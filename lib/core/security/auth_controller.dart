import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/remote/remote_auth_repository.dart';
import 'biometric_service.dart';
import 'secure_store.dart';

/// Estados del ciclo de vida de autenticación.
enum AuthStatus {
  /// Arranque: leyendo almacenamiento seguro.
  loading,

  /// No hay cuenta remota firmada (pide login/registro).
  needsAccount,

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
  AuthController(this._store, this._remote);

  final SecureStore _store;
  final RemoteAuthRepository? _remote;

  AuthStatus _status = AuthStatus.loading;
  AuthStatus get status => _status;

  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;

  bool _hasBiometrics = false;
  bool get hasBiometrics => _hasBiometrics;

  bool get canUseBiometricNow => _biometricEnabled && _hasBiometrics;

  /// ¿Cuenta remota activa? (Supabase configurada y con sesión)
  bool get signedInRemote => _remote?.isSignedIn ?? false;

  /// Email de la cuenta (sesión actual o el último usado en el dispositivo).
  String? _accountEmail;

  /// Email de la cuenta firmada (para mostrarlo en el dashboard).
  String? get remoteEmail => _remote?.email ?? _accountEmail;

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

    // 1) Autenticación remota (primera puerta).
    //    Solo exige cuenta si Supabase está configurado; si no,
    //    la app sigue 100% local como antes.
    await _remote?.initialize();
    final remote = _remote;
    if (remote != null && remote.enabled && !remote.isSignedIn) {
      _status = AuthStatus.needsAccount;
      notifyListeners();
      return;
    }

    // 2) App lock local (PIN/biometría) como segunda capa.
    final hasPin = await _store.hasPinConfigured();
    _biometricEnabled = await _store.isBiometricEnabled();
    _lockTimeoutSeconds = await _store.lockTimeoutSeconds();
    _hasBiometrics = await BiometricService.canAuthenticate();
    _accountEmail = await _store.accountEmail();

    _status = hasPin ? AuthStatus.locked : AuthStatus.needsPinSetup;
    notifyListeners();
  }

  // ---- Cuenta remota ----

  /// Devuelve null si OK, o un mensaje de error legible.
  Future<String?> signInRemote({
    required String email,
    required String password,
  }) async {
    final remote = _remote;
    if (remote == null || !remote.enabled) {
      return 'La cuenta no está configurada en esta compilación.';
    }
    try {
      await remote.signIn(email: email, password: password);
      await _store.saveAccountEmail(email.trim());
      _accountEmail = email.trim();
      await _continueAfterRemoteAuth();
      return null;
    } catch (e) {
      return _friendlyAuthError(e);
    }
  }

  /// Devuelve null si OK (o requiere confirmar correo), o mensaje de error.
  Future<String?> signUpRemote({
    required String email,
    required String password,
  }) async {
    final remote = _remote;
    if (remote == null || !remote.enabled) {
      return 'La cuenta no está configurada en esta compilación.';
    }
    try {
      await remote.signUp(email: email, password: password);
      // Guardamos el email aunque la confirmación esté pendiente:
      // así no se "pierde" y podemos pre-rellenar en login.
      await _store.saveAccountEmail(email.trim());
      _accountEmail = email.trim();
      if (remote.isSignedIn) {
        await _continueAfterRemoteAuth();
        return null;
      }
      // Confirmación pendiente: guardamos el email y damos contexto.
      return 'Tu cuenta se creó. Revisa tu correo para confirmarla y luego inicia sesión.';
    } catch (e) {
      return _friendlyAuthError(e);
    }
  }

  Future<void> signOutRemote() async {
    try {
      await _remote?.signOut();
    } catch (_) {
      // Si falla la red, igual limpiamos sesión local.
    }
    _status = AuthStatus.needsAccount;
    notifyListeners();
  }

  Future<void> _continueAfterRemoteAuth() async {
    final hasPin = await _store.hasPinConfigured();
    _biometricEnabled = await _store.isBiometricEnabled();
    _lockTimeoutSeconds = await _store.lockTimeoutSeconds();
    _hasBiometrics = await BiometricService.canAuthenticate();
    _status = hasPin ? AuthStatus.locked : AuthStatus.needsPinSetup;
    notifyListeners();
  }

  String _friendlyAuthError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (msg.contains('already registered')) {
      return 'Ese correo ya está registrado. Inicia sesión.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión.';
    }
    if (msg.contains('network')) {
      return 'Sin conexión. Revisa tu internet e intenta de nuevo.';
    }
    return 'No pudimos completar la acción. Intenta de nuevo.';
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
