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

  final int? age;
  final String? country;
  final String? address;

  const UserProfile({
    this.id = singletonId,
    this.name = '',
    this.age,
    this.country,
    this.address,
  });

  /// ¿Ya configuró su nombre?
  bool get hasName => name.trim().isNotEmpty;

  static const Object _unset = Object();

  UserProfile copyWith({
    String? id,
    String? name,
    Object? age = _unset,
    Object? country = _unset,
    Object? address = _unset,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: identical(age, _unset) ? this.age : age as int?,
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
          other.age == age &&
          other.country == country &&
          other.address == address);

  @override
  int get hashCode => Object.hash(id, name, age, country, address);

  @override
  String toString() =>
      'UserProfile($id, "$name", age=$age, country=$country)';
}