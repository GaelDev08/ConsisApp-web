import 'goal_type.dart';

/// Meta polivalente del sistema de hiperenfoque.
///
/// Puede haber muchas metas registradas; la UI mantiene UNA en foco
/// (selector/carrusel del dashboard) vía [AppSettings.activeGoalId].
class Goal {
  final String id;
  final GoalType type;
  final String title;

  final GoalFrequency frequency;
  final GoalUnit unit;
  final int targetValue; // 200 (min/sem) · 60 (min/día) · 20 (páginas/día)…

  /// Etiquetas de contexto (solo estudio): "Backend / Laravel", "Frontend"…
  final List<String> contextTags;

  /// Config de ayuno (solo [GoalType.fasting]).
  final FastingConfig? fasting;
/// Recordatorio opcional: hora diaria "HH:mm" (formato 24h; null = sin notificacion).
  ///
  /// Si se define, la app programa una notificacion local diaria a esa hora
  /// para que no se olvide realizar la tarea (solo movil; en Web se ignora).
  final String? scheduledTime;

  /// La meta requiere semáforo nutricional diario (dominio salud).
  ///
  /// Regla automática por tipo: fitness/fasting = true ·
  /// timeAccumulated = false · custom = elegido por el usuario.
  final bool requiresNutritionTracking;

  /// La meta requiere control de peso semanal (dominio salud).
  final bool requiresWeightTracking;

  final bool archived;
  final int sortOrder;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.type,
    required this.title,
    required this.frequency,
    required this.unit,
    required this.targetValue,
    this.contextTags = const [],
    this.fasting,
    this.scheduledTime,
    this.requiresNutritionTracking = true,
    this.requiresWeightTracking = true,
    this.archived = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Goal copyWith({
    String? id,
    GoalType? type,
    String? title,
    GoalFrequency? frequency,
    GoalUnit? unit,
    int? targetValue,
    List<String>? contextTags,
    Object? fasting = _unset,
    Object? scheduledTime = _unset,
    bool? requiresNutritionTracking,
    bool? requiresWeightTracking,
    bool? archived,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      unit: unit ?? this.unit,
      targetValue: targetValue ?? this.targetValue,
      contextTags: contextTags ?? this.contextTags,
      fasting: identical(fasting, _unset) ? this.fasting : fasting as FastingConfig?,
      scheduledTime: identical(scheduledTime, _unset)
          ? this.scheduledTime
          : scheduledTime as String?,
      requiresNutritionTracking:
          requiresNutritionTracking ?? this.requiresNutritionTracking,
      requiresWeightTracking:
          requiresWeightTracking ?? this.requiresWeightTracking,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const Object _unset = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Goal && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Goal($id, ${type.name}, "$title", '
      '${frequency.name}/${unit.name}/$targetValue)';
}
