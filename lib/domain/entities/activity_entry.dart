/// Sub-registro de una sesión fitness compuesta.
///
/// Permite guardar en UN solo registro: "Running 30 min + Caminata 10 min".
class ActivityEntry {
  final String name;
  final int minutes;

  const ActivityEntry({required this.name, required this.minutes});

  ActivityEntry copyWith({String? name, int? minutes}) => ActivityEntry(
        name: name ?? this.name,
        minutes: minutes ?? this.minutes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityEntry &&
          other.name == name &&
          other.minutes == minutes);

  @override
  int get hashCode => Object.hash(name, minutes);

  @override
  String toString() => '$name ${minutes}min';
}
