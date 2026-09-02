import '../entities/goal.dart';

/// Contrato CRUD de metas polivalentes (carrusel del dashboard).
abstract interface class GoalRepository {
  /// Todas las metas ordenadas por [Goal.sortOrder] y luego creación.
  Stream<List<Goal>> watchAll();

  /// Carga puntual (para resolver la meta activa al arrancar).
  Future<List<Goal>> loadAll();

  /// Inserta o actualiza (upsert por id).
  Future<void> save(Goal goal);

  Future<void> deleteById(String id);
}
