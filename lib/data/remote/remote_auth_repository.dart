import 'supabase_service.dart';

/// Contrato mínimo de autenticación remota (desacoplado de Supabase).
abstract class RemoteAuthRepository {
  bool get enabled;
  bool get isSignedIn;
  String? get userId;
  String? get email;
  Future<void> initialize();
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();
  Future<void> resetPassword({required String email, String? redirectTo});
}

/// Implementación con Supabase Auth.
class SupabaseAuthRepository implements RemoteAuthRepository {
  @override
  bool get enabled => SupabaseService.isConfigured;

  @override
  bool get isSignedIn {
    if (!enabled) return false;
    try {
      return SupabaseService.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  @override
  String? get userId {
    try {
      return SupabaseService.client.auth.currentSession?.user.id;
    } catch (_) {
      return null;
    }
  }

  @override
  String? get email {
    try {
      return SupabaseService.client.auth.currentSession?.user.email;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> initialize() async {
    if (enabled) await SupabaseService.ensureInitialized();
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await SupabaseService.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await SupabaseService.client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  @override
  Future<void> resetPassword({
    required String email,
    String? redirectTo,
  }) async {
    await SupabaseService.client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }
}