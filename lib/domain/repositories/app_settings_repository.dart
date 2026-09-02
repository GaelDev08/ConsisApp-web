import '../entities/app_settings.dart';

/// Contrato de los ajustes globales (caja singleton).
///
/// Incluye la configuración del **día de pesaje oficial** (1..7,
/// default lunes) y la meta semanal del único objetivo activo.
abstract interface class AppSettingsRepository {
  /// Stream reactivo de los ajustes; emite defaults si aún no existen.
  Stream<AppSettings> watch();

  /// Carga única con valores por defecto si la caja está vacía.
  Future<AppSettings> load();

  /// Reemplaza los ajustes completos (entidad inmutable + copyWith).
  Future<void> save(AppSettings settings);

  /// Atajo para cambiar solo el día de pesaje oficial.
  Future<void> updateWeighInWeekday(int weekday);
}
