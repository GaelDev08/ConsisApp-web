import '../entities/nutrition_check.dart';

/// Contrato del semáforo nutricional diario (check-in de 1 tap).
abstract interface class NutritionCheckRepository {
  Stream<List<NutritionCheck>> watchAll();

  /// Check-in de un día concreto (null si ese día no se registró nada).
  Future<NutritionCheck?> getByDay(DateTime day);

  /// Guarda o reemplaza el check-in del día ([check.day]).
  ///
  /// Si ya existía un check-in ese mismo día, se sobreescribe:
  /// el semáforo es siempre "el estado actual del día".
  Future<NutritionCheck> setForDay(NutritionCheck check);

  Future<void> deleteById(String id);
}
