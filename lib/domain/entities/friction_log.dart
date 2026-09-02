/// Bitácora de fricciones POR META ("¿Por qué no cumplí esta meta hoy?").
///
/// - [tag]: etiqueta predefinida de 1 tap (kFrictionPresetLabels).
/// - [customLabel]: texto libre del usuario.
/// Al menos una de las dos debe estar presente (validación repo/UI).
class FrictionLog {
  final String id;
  final String goalId;
  final DateTime day;
  final String? tag;
  final String? customLabel;
  final String? note;
  final DateTime createdAt;

  const FrictionLog({
    required this.id,
    required this.goalId,
    required this.day,
    required this.createdAt,
    this.tag,
    this.customLabel,
    this.note,
  });

  String get effectiveLabel {
    if (tag != null && tag!.trim().isNotEmpty) return tag!;
    if (customLabel != null && customLabel!.trim().isNotEmpty) {
      return customLabel!;
    }
    return 'Sin motivo';
  }

  bool get hasPresetTag => tag != null && tag!.trim().isNotEmpty;

  static const Object _sentinel = Object();

  FrictionLog copyWith({
    String? id,
    String? goalId,
    DateTime? day,
    Object? tag = _sentinel,
    Object? customLabel = _sentinel,
    Object? note = _sentinel,
    DateTime? createdAt,
  }) {
    return FrictionLog(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      day: day ?? this.day,
      tag: identical(tag, _sentinel) ? this.tag : tag as String?,
      customLabel: identical(customLabel, _sentinel)
          ? this.customLabel
          : customLabel as String?,
      note: identical(note, _sentinel) ? this.note : note as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FrictionLog && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FrictionLog($id, goal=$goalId, $day, $effectiveLabel)';
}
