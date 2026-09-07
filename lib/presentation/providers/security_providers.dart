import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/auth_controller.dart';
import '../../core/security/secure_store.dart';
import '../../data/remote/remote_auth_repository.dart';

/// Repositorio de autenticación remota (Supabase).
final remoteAuthRepositoryProvider = Provider<RemoteAuthRepository>(
  (_) => SupabaseAuthRepository(),
);

/// Controlador global de seguridad (sesión, PIN, biometría, timeouts).
final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    SecureStore.instance,
    ref.watch(remoteAuthRepositoryProvider),
  );
});
