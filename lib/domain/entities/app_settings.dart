/// Ajustes globales de la app.
///
/// - [activeGoalId]: meta EN FOCO del dashboard (selector/carrusel).
///   Cadena vacía = sin meta activa todavía.
/// - [weighInWeekday]: día oficial de pesaje usando `DateTime.weekday`
///   (1 = lunes … 7 = domingo; por defecto lunes).
///
/// La configuración de cada meta vive en la entidad [Goal] (multi-meta);
/// aquí solo queda el estado global transversal.
class AppSettings {
  /// Id fijo: la caja de ajustes contiene exactamente este registro.
  static const String singletonId = 'app_settings_singleton';

  /// Días válidos para el pesaje oficial (1..7, DateTime.weekday).
  static const int minWeekday = 1;
  static const int maxWeekday = 7;

  /// Color ARGB por defecto del fondo de la app (negro premium de ConsisApp).
  /// Se guarda como int para que la entidad de dominio siga pura (sin Flutter).
  static const int defaultBgColor = 0xFF121218;

  final String id;
  final String activeGoalId;
  final int weighInWeekday;

  /// Color ARGB del fondo (0xAARRGGBB; por defecto [defaultBgColor]).
  final int backgroundColorValue;

  const AppSettings({
    this.id = singletonId,
    this.activeGoalId = '',
    this.weighInWeekday = DateTime.monday,
    this.backgroundColorValue = defaultBgColor,
  }) : assert(
          weighInWeekday >= minWeekday && weighInWeekday <= maxWeekday,
          'weighInWeekday debe estar entre 1 (lunes) y 7 (domingo)',
        );

  bool get hasActiveGoal => activeGoalId.trim().isNotEmpty;

  AppSettings copyWith({
    String? id,
    String? activeGoalId,
    int? weighInWeekday,
    int? backgroundColorValue,
  }) {
    return AppSettings(
      id: id ?? this.id,
      activeGoalId: activeGoalId ?? this.activeGoalId,
      weighInWeekday: weighInWeekday ?? this.weighInWeekday,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettings &&
          other.id == id &&
          other.activeGoalId == activeGoalId &&
          other.weighInWeekday == weighInWeekday &&
          other.backgroundColorValue == backgroundColorValue);

  @override
  int get hashCode => Object.hash(id, activeGoalId, weighInWeekday, backgroundColorValue);

  @override
  String toString() =>
      'AppSettings($id, activeGoal="$activeGoalId", weekday=$weighInWeekday, '
      'bg=0x${backgroundColorValue.toRadixString(16)})';
}

