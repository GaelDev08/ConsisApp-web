import 'package:consis_app/core/utils/datetime_x.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/domain/entities/nutrition_check.dart';
import 'package:consis_app/domain/entities/nutrition_level.dart';

/// Matemática de semanas (inicio lunes, igual que el día de pesaje default).
///
/// Funciones puras del dominio: sin Flutter, sin Hive → testeables.
abstract final class WeekMath {
  /// Lunes 00:00 de la semana a la que pertenece [day].
  static DateTime mondayOf(DateTime day) =>
      day.dateOnly.subtract(Duration(days: day.weekday - DateTime.monday));

  /// Domingo 00:00 de la semana de [day].
  static DateTime sundayOf(DateTime day) =>
      mondayOf(day).add(const Duration(days: 6));

  /// ¿[day] cae dentro de la semana (lunes-domingo) de [reference]?
  static bool isWithinWeekOf(DateTime day, DateTime reference) {
    final monday = mondayOf(reference);
    final nextMonday = monday.add(const Duration(days: 7));
    final d = day.dateOnly;
    return !d.isBefore(monday) && d.isBefore(nextMonday);
  }

  /// Suma de minutos de las sesiones dentro de [startInclusive, endExclusive).
  static int totalMinutesBetween(
    List<SessionEntry> sessions,
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    var total = 0;
    for (final s in sessions) {
      final d = s.day.dateOnly;
      if (!d.isBefore(startInclusive) && d.isBefore(endExclusive)) {
        total += s.durationMinutes;
      }
    }
    return total;
  }

  /// Días calendario distintos con al menos una sesión.
  static Set<DateTime> distinctDays(List<SessionEntry> sessions) =>
      sessions.map((s) => s.day.dateOnly).toSet();

  /// Mapa día → nivel nutricional (último registro gana tras normalizar).
  static Map<DateTime, NutritionLevel> checksByDay(
    List<NutritionCheck> checks,
  ) =>
      {for (final c in checks) c.day.dateOnly: c.level};

  /// Días hasta la próxima ocurrencia de [targetWeekday] desde [from]
  /// (0 = hoy). Usa la convención DateTime.weekday (1=lunes…7=domingo).
  static int daysUntilWeekday(DateTime from, int targetWeekday) =>
      (targetWeekday - from.weekday + 7) % 7;
}
