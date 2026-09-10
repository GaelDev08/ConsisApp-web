/// Perfil básico del usuario (caja singleton cifrada).
///
/// [name] es el único campo requerido: alimenta el saludo dinámico
/// del dashboard. El resto son opcionales.
class UserProfile {
  /// Id fijo: la caja contiene exactamente este registro.
  static const String singletonId = 'user_profile_singleton';

  final String id;

  /// Nombre mostrado en el saludo (ej. "Cesar"). Vacío = sin configurar.
  final String name;

  final DateTime? birthdate;
  final String? country;
  final String? address;

  const UserProfile({
    this.id = singletonId,
    this.name = '',
    this.birthdate,
    this.country,
    this.address,
  });

  /// ¿Ya configuró su nombre?
  bool get hasName => name.trim().isNotEmpty;

  static const Object _unset = Object();

  UserProfile copyWith({
    String? id,
    String? name,
    Object? birthdate = _unset,
    Object? country = _unset,
    Object? address = _unset,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      birthdate: identical(birthdate, _unset) ? this.birthdate : birthdate as DateTime?,
      country:
          identical(country, _unset) ? this.country : country as String?,
      address:
          identical(address, _unset) ? this.address : address as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == id &&
          other.name == name &&
          other.birthdate == birthdate &&
          other.country == country &&
          other.address == address);

  @override
  int get hashCode => Object.hash(id, name, birthdate, country, address);

  @override
  String toString() =>
      'UserProfile($id, "$name", birthdate=$birthdate, country=$country)';
}