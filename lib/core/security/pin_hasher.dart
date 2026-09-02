import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Utilidades de hash para el PIN de 4 dígitos.
///
/// Nunca se almacena el PIN en claro: se guarda
/// `PBKDF2-HMAC-SHA256(pin, salt)` con sal aleatoria por instalación y
/// comparación en tiempo constante para evitar timing attacks.
abstract final class PinHasher {
  static const int _iterations = 100000;
  static const int _keyLength = 32;

  static final RegExp _fourDigits = RegExp(r'^\d{4}$');

  /// ¿[pin] tiene exactamente 4 dígitos numéricos?
  static bool isValidFormat(String pin) => _fourDigits.hasMatch(pin);

  /// Genera una sal aleatoria de 16 bytes codificada en Base64.
  static String generateSalt() {
    final rnd = Random.secure();
    return base64Encode(
      List<int>.generate(16, (_) => rnd.nextInt(256), growable: false),
    );
  }

  /// Hash del [pin] usando la [saltBase64] dada.
  static String hashPin(String pin, String saltBase64) {
    final derived = _pbkdf2HmacSha256(
      utf8.encode(pin),
      base64Decode(saltBase64),
    );
    return base64Encode(derived);
  }

  /// Comparación segura (tiempo constante) contra el hash esperado.
  static bool verifyPin(String pin, String saltBase64, String expectedHashB64) {
    final actual = hashPin(pin, saltBase64);
    return _constantTimeEquals(actual, expectedHashB64);
  }

  // ---- internals ----

  static Uint8List _pbkdf2HmacSha256(List<int> password, List<int> salt) {
    final hmac = Hmac(sha256, password);
    final blocksNeeded = (_keyLength / 32).ceil();
    final derived = BytesBuilder();

    for (var block = 1; block <= blocksNeeded; block++) {
      final blockIndex = Uint8List(4);
      blockIndex[0] = (block >> 24) & 0xff;
      blockIndex[1] = (block >> 16) & 0xff;
      blockIndex[2] = (block >> 8) & 0xff;
      blockIndex[3] = block & 0xff;

      var u = hmac.convert(<int>[...salt, ...blockIndex]).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < _iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      derived.add(t);
    }

    return Uint8List.fromList(derived.toBytes().sublist(0, _keyLength));
  }

  static bool _constantTimeEquals(String a, String b) {
    final ab = utf8.encode(a);
    final bb = utf8.encode(b);
    if (ab.length != bb.length) return false;
    var diff = 0;
    for (var i = 0; i < ab.length; i++) {
      diff |= ab[i] ^ bb[i];
    }
    return diff == 0;
  }
}
