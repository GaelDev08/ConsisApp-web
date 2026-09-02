import 'dart:async';

import 'package:flutter/foundation.dart';

import 'biometric_service.dart';
import 'secure_store.dart';

/// Estados del ciclo de vida de autenticación.
enum AuthStatus {
  /// Arranque: leyendo almacenamiento seguro.
  loading,

  /// Primera vez: crear + confirmar PIN.
  needsPinSetup,

  /// Sesión bloqueada (arranque, rebloqueo o manual).
  locked,

  /// PIN/biometría verificados.
  unlocked,
}

/// Máquina de estados de la capa de seguridad.
///
/// Reglas clave:
/// - El PIN jamás se guarda en claro (hash PBKDF2 en [SecureStore]).
/// - Biometría: solo si el toggle está activo Y el dispositivo soporta
///   (`local_auth`). En web `hasBiometrics` es siempre false.
/// - Rebloqueo configurable: al volver de 2º plano solo se bloquea si
///   transcurrieron ≥ [lockTimeoutSeconds] (0 = bloqueo inmediato).
class AuthController extends ChangeNotifier {
  AuthController(this._store);

  final SecureStore _store;

  AuthStatus _status = AuthStatus.loading;
  AuthStatus get status => _status;

  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;

  bool _hasBiometrics = false;
  bool get hasBiometrics => _hasBiometrics;

  bool get canUseBiometricNow => _biometricEnabled && _hasBiometrics;

  int _lockTimeoutSeconds = SecureStore.defaultLockTimeoutSeconds;
  int get lockTimeoutSeconds => _lockTimeoutSeconds;

  static const int _maxAttempts = 5;
  static const int _cooldownSeconds = 60;

  int _failedAttempts = 0;
  DateTime? _cooldownUntil;

  bool get isCoolingDown =>
      _cooldownUntil != null &&
      DateTime.now().isBefore(_cooldownUntil!);

  int get cooldownRemainingSeconds {
    if (!isCoolingDown) return 0;
    return _cooldownUntil!.difference(DateTime.now()).inSeconds + 1;
  }

  DateTime? _backgroundedAt;
  bool _initialized = false;
  bool _autoPromptedThisSession = false;

  /// Idempotente: se llama una vez al arrancar (post-frame desde AuthGate).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final hasPin = await _store.hasPinConfigured();
    _biometricEnabled = await _store.isBiometricEnabled();
    _lockTimeoutSeconds = await _store.lockTimeoutSeconds();
    _hasBiometrics = await BiometricService.canAuthenticate();

    _status = hasPin ? AuthStatus.locked : AuthStatus.needsPinSetup;
    notifyListeners();
  }

  // ---- Desbloqueo ----

  Future<bool> unlockWithPin(String pin) async {
    if (isCoolingDown) return false;
    final ok = await _store.verifyPin(pin);
    if (ok) {
      _failedAttempts = 0;
      _status = AuthStatus.unlocked;
      notifyListeners();
      return true;
    }
    _failedAttempts++;
    if (_failedAttempts >= _maxAttempts) {
      _cooldownUntil =
          DateTime.now().add(const Duration(seconds: _cooldownSeconds));
      _failedAttempts = 0;
    }
    notifyListeners();
    return false;
  }

  Future<bool> unlockWithBiometric() async {
    if (!canUseBiometricNow || isCoolingDown) return false;
    final ok = await BiometricService.authenticate(
      localizedReason: 'Desbloquea ConsisApp para continuar',
    );
    if (ok) {
      _failedAttempts = 0;
      _status = AuthStatus.unlocked;
      notifyListeners();
    }
    return ok;
  }

  /// Auto-disparo único del lector biométrico por sesión de app
  /// (al abrir o al volver de segundo plano ya bloqueada).
  Future<bool> tryAutoBiometric() async {
    if (_autoPromptedThisSession) return false;
    if (_status != AuthStatus.locked || !canUseBiometricNow) return false;
    _autoPromptedThisSession = true;
    return unlockWithBiometric();
  }

  // ---- Configuración inicial / cambio de PIN ----

  Future<void> setupPin(String pin) async {
    assert(PinFormat.isValid(pin), 'El PIN debe tener 4 dígitos');
    await _store.savePin(pin);
    _status = AuthStatus.unlocked;
    notifyListeners();
  }

  /// Verificación directa (flujo "Cambiar PIN", dentro de sesión válida).
  Future<bool> verifyPin(String pin) => _store.verifyPin(pin);

  Future<void> changePin(String newPin) async {
    assert(PinFormat.isValid(newPin), 'El PIN debe tener 4 dígitos');
    await _store.savePin(newPin);
    notifyListeners();
  }

  // ---- Ciclo de vida ----

  void markBackgrounded() {
    if (_status == AuthStatus.unlocked) {
      _backgroundedAt = DateTime.now();
    }
  }

  /// Al volver a primer plano decide si corresponde rebloquear según
  /// el timeout configurado (0 = inmediato).
  void maybeRelockOnResume() {
    final bgAt = _backgroundedAt;
    _backgroundedAt = null;
    if (bgAt == null) return;

    if (_status != AuthStatus.unlocked) return;

    final elapsed = DateTime.now().difference(bgAt).inSeconds;
    if (elapsed >= _lockTimeoutSeconds) {
      _autoPromptedThisSession = false; // permite nuevo auto-intento
      _status = AuthStatus.locked;
      notifyListeners();
      unawaited(tryAutoBiometric());
    }
  }

  void lockNow() {
    _backgroundedAt = null;
    _autoPromptedThisSession = false;
    if (_status == AuthStatus.unlocked) {
      _status = AuthStatus.locked;
      notifyListeners();
    }
  }

  // ---- Preferencias ----

  Future<void> setBiometricEnabled(bool value) async {
    await _store.setBiometricEnabled(value);
    _biometricEnabled = value;
    notifyListeners();
  }

  Future<void> setLockTimeout(int seconds) async {
    final safe = SecureStore.allowedLockTimeouts.contains(seconds)
        ? seconds
        : SecureStore.defaultLockTimeoutSeconds;
    await _store.setLockTimeoutSeconds(safe);
    _lockTimeoutSeconds = safe;
    notifyListeners();
  }
}

/// Validación de formato compartida (evita import extra en UI).
abstract final class PinFormat {
  static bool isValid(String pin) =>
      pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
}
