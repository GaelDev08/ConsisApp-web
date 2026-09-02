import '../entities/friction_log.dart';

/// Contrato de la bitácora de fricciones POR META.
abstract interface class FrictionLogRepository {
  Stream<List<FrictionLog>> watchAll();

  Stream<List<FrictionLog>> watchByGoal(String goalId);

  Future<List<FrictionLog>> findByDay(DateTime day);

  /// Registra un motivo rápido: etiqueta predefinida ([tag]),
  /// texto libre ([customLabel]) o ambos + nota.
  Future<FrictionLog> add({
    required String goalId,
    required DateTime day,
    String? tag,
    String? customLabel,
    String? note,
  });

  Future<void> deleteById(String id);
}
