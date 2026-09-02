import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/auth_controller.dart';
import '../../core/security/secure_store.dart';

/// Controlador global de seguridad (sesión, PIN, biometría, timeouts).
final authControllerProvider = ChangeNotifierProvider<AuthController>(
  (ref) => AuthController(SecureStore.instance),
);
