import '../entities/weight_record.dart';

/// Contrato del historial de peso semanal.
abstract interface class WeightRecordRepository {
  /// Historial completo ordenado por fecha ascendente.
  Stream<List<WeightRecord>> watchAll();

  /// Último pesaje registrado (para el recordatorio del dashboard).
  Future<WeightRecord?> latest();

  /// Guarda/actualiza el pesaje del día oficial.
  Future<WeightRecord> save({required DateTime date, required double weightKg});

  /// Carga masiva de historial previo (últimos 3 meses u otros).
  /// Omite fechas ya registradas; devuelve cuántos se insertaron.
  Future<int> importHistory(List<WeightRecord> records);

  Future<void> deleteById(String id);
}
