import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/security/secure_store.dart';
import 'data/local/hive_manager.dart';
import 'presentation/app/consis_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Clave AES-256 desde almacenamiento seguro (Keystore/Keychain/WebCrypto).
  //    Se genera UNA sola vez por instalación; sin ella las boxes cifradas
  //    son ilegibles (borrar datos de la app ⇒ regenerar desde cero).
  final aesKey = await SecureStore.instance.ensureAesKey();

  // 2) Bootstrap de persistencia local CIFRADA (Web/IndexedDB + Móvil).
  //    La barrera de sesión la impone <AuthGate> sobre el árbol de UI.
  await HiveManager.ensureInitialized(aesKey: aesKey);

  runApp(const ProviderScope(child: ConsisApp()));
}

