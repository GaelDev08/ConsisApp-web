import 'nutrition_level.dart';

/// Check-in diario del semáforo nutricional (registro de 1 tap).
///
/// Un registro por día calendario; volver a tocar el semáforo el mismo
/// día reemplaza el valor anterior (lógica a nivel repositorio).
class NutritionCheck {
  final String id;
  final DateTime day;
  final NutritionLevel level;
  final String? note;

  const NutritionCheck({
    required this.id,
    required this.day,
    required this.level,
    this.note,
  });

  static const Object _sentinel = Object();

  NutritionCheck copyWith({
    String? id,
    DateTime? day,
    NutritionLevel? level,
    Object? note = _sentinel,
  }) {
    return NutritionCheck(
      id: id ?? this.id,
      day: day ?? this.day,
      level: level ?? this.level,
      note: identical(note, _sentinel) ? this.note : note as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is NutritionCheck && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'NutritionCheck($id, $day, ${level.name})';
}
