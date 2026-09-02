import '../entities/user_profile.dart';

/// Contrato del perfil de usuario (caja singleton).
abstract interface class UserProfileRepository {
  /// Perfil reactivo; emite defaults si aún no se ha configurado.
  Stream<UserProfile> watch();

  /// Carga puntual con valores por defecto si la caja está vacía.
  Future<UserProfile> load();

  /// Reemplaza el perfil completo (entidad inmutable + copyWith).
  Future<void> save(UserProfile profile);
}