import 'activity_entry.dart';

/// Registro unificado de actividad para TODOS los tipos de meta.
///
/// - timeAccumulated: [durationMinutes] + [tags] de contexto.
/// - fitness: [activities] compuestas (la suma = [durationMinutes]).
/// - fasting: [fastingStartAt]/[fastingEndAt]; endAt null ⇒ ayuno EN CURSO.
/// - custom: [quantity] en la unidad de la meta.
class SessionEntry {
  final String id;
  final String goalId;

  /// Fecha normalizada a medianoche local (acumulación diaria/semanal).
  final DateTime day;

  final int durationMinutes;
  final double? quantity;

  final List<ActivityEntry> activities;
  final List<String> tags;

  final DateTime? fastingStartAt;
  final DateTime? fastingEndAt;

  final String? note;
  final DateTime createdAt;

  const SessionEntry({
    required this.id,
    required this.goalId,
    required this.day,
    this.durationMinutes = 0,
    this.quantity,
    this.activities = const [],
    this.tags = const [],
    this.fastingStartAt,
    this.fastingEndAt,
    this.note,
    required this.createdAt,
  });

  bool get isFasting => fastingStartAt != null;

  /// Ayuno EN CURSO (timer real-time): startAt presente, endAt ausente.
  bool get isActiveFast => isFasting && fastingEndAt == null;

  /// Horas continuas transcurridas del ayuno (en vivo si está activo).
  Duration fastingElapsed({DateTime? now}) {
    final start = fastingStartAt;
    if (start == null) return Duration.zero;
    final end = fastingEndAt ?? now ?? DateTime.now();
    final diff = end.difference(start);
    return diff.isNegative ? Duration.zero : diff;
  }

  SessionEntry copyWith({
    String? id,
    String? goalId,
    DateTime? day,
    int? durationMinutes,
    double? quantity,
    List<ActivityEntry>? activities,
    List<String>? tags,
    DateTime? fastingStartAt,
    DateTime? fastingEndAt,
    String? note,
    DateTime? createdAt,
  }) {
    return SessionEntry(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      day: day ?? this.day,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      quantity: quantity ?? this.quantity,
      activities: activities ?? this.activities,
      tags: tags ?? this.tags,
      fastingStartAt: fastingStartAt ?? this.fastingStartAt,
      fastingEndAt: fastingEndAt ?? this.fastingEndAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SessionEntry && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SessionEntry($id, goal=$goalId, $day, '
      '${durationMinutes}min${isActiveFast ? ', ACTIVE FAST' : ''})';
}
