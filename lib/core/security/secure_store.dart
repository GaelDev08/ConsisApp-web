import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/security/pin_hasher.dart';

/// Claves usadas en el almacenamiento seguro.
abstract final class SecureStoreKeys {
  static const String pinSalt = 'pin_salt';
  static const String pinHash = 'pin_hash';
  static const String aesKey = 'aes_key_b64';
  static const String biometricEnabled = 'biometric_enabled';
  static const String lockTimeoutSeconds = 'lock_timeout_seconds';
  static const String accountEmail = 'account_email';
}

/// Wrapper tipado sobre FlutterSecureStorage.
///
/// - Android/iOS: Keystore/Keychain real.
/// - Web (Vercel HTTPS): WebCrypto/localStorage — mejor esfuerzo posible
///   en navegador; la barrera fuerte es el propio flujo de bloqueo.
final class SecureStore {
  SecureStore._();

  static final SecureStore instance = SecureStore._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const int defaultLockTimeoutSeconds = 30;
  static const Set<int> allowedLockTimeouts = {0, 15, 30, 60};

  // ---- Clave AES para Hive ----

  /// Lee o crea (una sola vez) la clave AES-256 que cifra las boxes Hive.
  Future<List<int>> ensureAesKey() async {
    final existing = await _storage.read(key: SecureStoreKeys.aesKey);
    if (existing != null && existing.isNotEmpty) {
      return base64Decode(existing);
    }
    final rnd = Random.secure();
    final key = List<int>.generate(32, (_) => rnd.nextInt(256));
    await _storage.write(key: SecureStoreKeys.aesKey, value: base64Encode(key));
    return key;
  }

  // ---- PIN ----

  Future<bool> hasPinConfigured() async {
    final salt = await _storage.read(key: SecureStoreKeys.pinSalt);
    final hash = await _storage.read(key: SecureStoreKeys.pinHash);
    return salt != null && hash != null;
  }

  Future<void> savePin(String pin) async {
    final salt = PinHasher.generateSalt();
    await _storage.write(key: SecureStoreKeys.pinSalt, value: salt);
    await _storage.write(
      key: SecureStoreKeys.pinHash,
      value: PinHasher.hashPin(pin, salt),
    );
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: SecureStoreKeys.pinSalt);
    final hash = await _storage.read(key: SecureStoreKeys.pinHash);
    if (salt == null || hash == null) return false;
    return PinHasher.verifyPin(pin, salt, hash);
  }

  // ---- Preferencias de seguridad ----

  Future<bool> isBiometricEnabled() async {
    final raw = await _storage.read(key: SecureStoreKeys.biometricEnabled);
    return raw == 'true';
  }

  Future<void> setBiometricEnabled(bool value) =>
      _storage.write(
        key: SecureStoreKeys.biometricEnabled,
        value: value ? 'true' : 'false',
      );

  Future<int> lockTimeoutSeconds() async {
    final raw = await _storage.read(key: SecureStoreKeys.lockTimeoutSeconds);
    final parsed = int.tryParse(raw ?? '');
    if (parsed == null || !allowedLockTimeouts.contains(parsed)) {
      return defaultLockTimeoutSeconds;
    }
    return parsed;
  }

  Future<void> setLockTimeoutSeconds(int seconds) => _storage.write(
        key: SecureStoreKeys.lockTimeoutSeconds,
        value: '$seconds',
      );

  // ---- Cuenta ----

  /// Email de la cuenta usada (se guarda localmente para prefil y estado).
  Future<void> saveAccountEmail(String email) =>
      _storage.write(key: SecureStoreKeys.accountEmail, value: email);

  Future<String?> accountEmail() =>
      _storage.read(key: SecureStoreKeys.accountEmail);
}
