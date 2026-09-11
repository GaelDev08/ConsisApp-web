import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Eventos de autenticación remota relevantes para la interfaz.
enum RemoteAuthEvent {
  /// La app se abrió desde un enlace de recuperación de contraseña
  /// (`type=recovery`): hay que pedir una nueva contraseña.
  passwordRecovery,
}

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

  /// Observa eventos de autenticación remota.
  ///
  /// El flujo subyacente es un ReplaySubject: si la app se abrió desde un
  /// enlace `type=recovery`, el evento ya se emitió durante el arranque y se
  /// vuelve a entregar aquí al suscribirse.
  StreamSubscription<RemoteAuthEvent> listen(
    void Function(RemoteAuthEvent event) onEvent,
  );

  /// ¿El flujo de recuperación ya fue detectado por el cliente remoto
  /// (aunque el evento llegue después de la suscripción)?
  bool get hasPendingPasswordRecovery;

  /// Cambia la contraseña de la sesión actual (flujo de recuperación).
  Future<void> updatePassword({required String newPassword});
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
  bool get hasPendingPasswordRecovery => _recoveryObserved;

  bool _recoveryListened = false;
  bool _recoveryObserved = false;

  @override
  Future<void> initialize() async {
    if (!enabled) return;
    await SupabaseService.ensureInitialized();

    // Observador temprano: captura el evento passwordRecovery incluso si se
    // emite antes de que AuthController se suscriba (ReplaySubject re-emite
    // el último evento, pero uno posterior podría pisarlo).
    if (_recoveryListened) return;
    _recoveryListened = true;
    try {
      SupabaseService.client.auth.onAuthStateChange.listen(
        (data) {
          if (data.event == AuthChangeEvent.passwordRecovery) {
            _recoveryObserved = true;
          }
        },
        onError: (error, stackTrace) {
          // Los errores (red/refresh) ya los registra GoTrueClient;
          // aquí solo evitamos que se relancen como errores no manejados.
        },
      );
    } catch (_) {
      // Cliente no inicializado: no hay eventos que capturar.
    }
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
  StreamSubscription<RemoteAuthEvent> listen(
    void Function(RemoteAuthEvent event) onEvent,
  ) {
    // Solo se invoca tras [initialize], que garantiza cliente activo.
    return SupabaseService.client.auth.onAuthStateChange
        .where((data) => data.event == AuthChangeEvent.passwordRecovery)
        .map((_) => RemoteAuthEvent.passwordRecovery)
        .listen(onEvent, onError: (error, stackTrace) {
          // Los errores (red/refresh) ya los registra GoTrueClient;
          // aquí solo evitamos que se relancen como errores no manejados.
        });
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await SupabaseService.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    String? redirectTo,
  }) async {
    await SupabaseService.client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo ?? _appRedirectUrl(),
    );
  }

  /// URL actual de la app (sin query ni fragment) para que el enlace del
  /// correo reabra la app y no una página alojada por Supabase.
  String? _appRedirectUrl() {
    try {
      final raw = Uri.base.toString();
      final cut = raw.split('#').first.split('?').first;
      return cut.isEmpty ? null : cut;
    } catch (_) {
      return null;
    }
  }
}