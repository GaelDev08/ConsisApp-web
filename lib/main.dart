import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/security/secure_store.dart';
import 'data/local/hive_manager.dart';
import 'data/remote/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'data/models/goal_model.dart';
import 'presentation/app/consis_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Supabase (si hay credenciales definidas; si no, app local).
  //    Las credenciales van con --dart-define al compilar.
  try {
    await SupabaseService.ensureInitialized();
  } catch (_) {
    // Si falla la red/config, seguimos en modo local (sin cuenta).
  }

  // 2) Clave AES-256 desde almacenamiento seguro (Keystore/Keychain/WebCrypto).
  //    Se genera UNA sola vez por instalación; sin ella las boxes cifradas
  //    son ilegibles (borrar datos de la app ⇒ regenerar desde cero).
  final aesKey = await SecureStore.instance.ensureAesKey();

  // 3) Bootstrap de persistencia local CIFRADA (Web/IndexedDB + Móvil).
  await HiveManager.ensureInitialized(aesKey: aesKey);

  // 4) Notificaciones locales (solo móvil: reprograma recordatorios al arrancar. En
  //    Web se omiten automáticamente (kIsWeb); nunca bloquean el arranque.
  try {
    await NotificationService.ensureInitialized();
    final existingGoals = HiveManager.goals.values
        .map((GoalModel m) => m.toEntity())
        .toList();
    await NotificationService.rescheduleAll(existingGoals);
  } catch (_) {
    // Las notificaciones nunca deben impedir el arranque de la app.-
  }

  runApp(const ProviderScope(child: ConsisApp()));
}

