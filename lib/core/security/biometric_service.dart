import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

/// Wrapper de biometría (`local_auth`).
///
/// Regla de negocio: en Web NUNCA se dispara biometría — `local_auth` no
/// soporta navegador; el fallback es siempre el teclado numérico del PIN.
abstract final class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Plataformas donde la biometría tiene sentido (móvil/desktop nativo).
  static bool get isSupportedPlatform => !kIsWeb;

  /// Hardware presente + biometría/dato de seguridad enrolado.
  static Future<bool> canAuthenticate() async {
    if (!isSupportedPlatform) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final deviceOk = await _auth.isDeviceSupported();
      return canCheck || deviceOk;
    } catch (_) {
      return false;
    }
  }

  /// Lanza el lector biométrico del sistema. Devuelve true si autenticó.
  static Future<bool> authenticate({required String localizedReason}) async {
    if (!isSupportedPlatform) return false;
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
      );
    } catch (_) {
      // Cancelación por el usuario, sin hardware enrolado, lockout, etc.
      return false;
    }
  }
}
