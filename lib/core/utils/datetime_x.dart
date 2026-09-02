/// Utilidades de fechas para semántica "día calendario".
///
/// Todos los modelos de ConsisApp normalizan sus fechas a medianoche local
/// ([dateOnly]) para que las agregaciones semanales/mensuales (Fase 4)
/// comparen días exactos sin ruido horario.
extension DateTimeX on DateTime {
  /// Misma fecha truncada a medianoche local.
  DateTime get dateOnly => DateTime(year, month, day);

  /// ¿Es el mismo día calendario que [other]?
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Lunes de la semana actual (semana inicia en lunes, igual que el
  /// día de pesaje por defecto).
  DateTime get startOfWeek {
    final d = dateOnly;
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }
}
