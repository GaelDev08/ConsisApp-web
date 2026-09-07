import 'package:supabase_flutter/supabase_flutter.dart';

/// Inicialización del cliente Supabase.
///
/// Credenciales "publishable" (públicas por diseño; la seguridad real la
/// dan las políticas RLS de `supabase/schema.sql`). Se pueden reemplazar
/// en compilación con:
///   flutter run --dart-define=SUPABASE_URL=... \
///               --dart-define=SUPABASE_ANON_KEY=...
abstract final class SupabaseService {
  static const String _envUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xjtfadxesdynmjiufosz.supabase.co',
  );
  static const String _envAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_7J0f-lKSux8o0577y6u1sQ_PWR9BFwb',
  );

  static bool _initialized = false;

  /// ¿Hay credenciales configuradas? Si no, los flujos de cuenta se ocultan.
  static bool get isConfigured => _envUrl.isNotEmpty && _envAnonKey.isNotEmpty;

  /// Idempotente: inicializa el cliente una sola vez.
  static Future<void> ensureInitialized() async {
    if (_initialized || !isConfigured) return;
    await Supabase.initialize(
      url: _envUrl,
      publishableKey: _envAnonKey,
    );
    _initialized = true;
  }

  static SupabaseClient get client {
    if (!_initialized && isConfigured) {
      throw StateError(
          'Supabase no inicializado: llama a ensureInitialized() en main.');
    }
    if (!isConfigured) {
      throw StateError('Supabase no configurado (usa --dart-define).');
    }
    return Supabase.instance.client;
  }
}