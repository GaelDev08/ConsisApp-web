/// Cálculo de horas continuas del ayuno intermitente (tiempo real).
abstract final class FastingCalculator {
  /// Tiempo transcurrido desde [startAt] hasta [endAt]
  /// (o hasta [now] si el ayuno sigue EN CURSO). Nunca negativo.
  static Duration elapsed({
    required DateTime startAt,
    DateTime? endAt,
    DateTime? now,
  }) {
    final effectiveEnd = endAt ?? now ?? DateTime.now();
    final diff = effectiveEnd.difference(startAt);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Horas en decimal (ej. 16.5 h) para comparar contra la meta.
  static double hoursDouble(Duration duration) =>
      duration.inMinutes / 60.0;

  /// Formato compacto "16h 05m".
  static String formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  /// ¿El ayuno ya alcanzó las horas objetivo?
  static bool reachedGoal({
    required Duration elapsed,
    required int fastHoursGoal,
  }) =>
      elapsed.inMinutes >= fastHoursGoal * 60;
}
