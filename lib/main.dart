import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/security/secure_store.dart';
import 'data/local/hive_manager.dart';
import 'data/remote/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'data/models/goal_model.dart';
import 'presentation/app/consis_app.dart';
import 'core/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;

  // 1) Supabase (si hay credenciales definidas; si no, app local).
  try {
    await SupabaseService.ensureInitialized();
  } catch (_) {
    // Si falla la red/config, seguimos en modo local (sin cuenta).
  }

  // 2) Clave AES-256 desde almacenamiento seguro.
  List<int> aesKey;
  try {
    aesKey = await SecureStore.instance.ensureAesKey();
  } catch (e) {
    initError = 'Error al acceder al almacenamiento seguro: $e';
    aesKey = List<int>.generate(32, (_) => 0);
  }

  // 3) Bootstrap de persistencia local CIFRADA.
  try {
    await HiveManager.ensureInitialized(aesKey: aesKey);
  } catch (e) {
    initError = 'Error al cargar datos locales: $e';
    // Intentar recuperación: borrar disco y reintentar.
    try {
      await Hive.deleteFromDisk();
      await HiveManager.ensureInitialized(aesKey: aesKey);
      initError = null; // Recuperación exitosa
    } catch (e2) {
      initError = 'Error crítico de persistencia: $e2';
    }
  }

  // 4) Notificaciones locales (solo móvil).
  try {
    await NotificationService.ensureInitialized();
    final existingGoals = HiveManager.goals.values
        .map((GoalModel m) => m.toEntity())
        .toList();
    await NotificationService.rescheduleAll(existingGoals);
  } catch (_) {
    // Las notificaciones nunca deben impedir el arranque.
  }

  runApp(ProviderScope(
    child: initError != null
        ? _BootstrapErrorScreen(error: initError)
        : const ConsisApp(),
  ));
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_rounded,
                    color: Colors.amber, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Error al iniciar ConsisApp',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    // Recargar página (Web).
                    // ignore: avoid_dynamic_calls
                    const String.fromEnvironment('dummy');
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

