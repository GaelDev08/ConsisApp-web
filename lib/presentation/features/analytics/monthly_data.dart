import 'package:consis_app/core/utils/datetime_x.dart';
import 'package:consis_app/domain/entities/friction_log.dart';
import 'package:consis_app/domain/entities/nutrition_check.dart';
import 'package:consis_app/domain/entities/nutrition_level.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/domain/entities/weight_record.dart';
import 'package:consis_app/domain/services/week_math.dart';

/// View-model inmutable de la vista analítica MENSUAL.
///
/// Todo se calcula sobre días normalizados a medianoche y rangos
/// [monthStart, nextMonth).
class MonthlyData {
  /// Primer día del mes (00:00 local).
  final DateTime monthStart;

  /// Día → nivel del semáforo nutricional registrado.
  final Map<DateTime, NutritionLevel> nutritionByDay;

  /// Días con al menos una sesión de minutos.
  final Set<DateTime> sessionDays;

  /// Días con al menos una entrada en la bitácora de fricciones.
  final Set<DateTime> frictionDays;

  /// Fechas con pesaje registrado.
  final Set<DateTime> weighInDays;

  final int totalMinutes;
  final int sessionsCount;

  /// Motivos agregados del mes, ordenados por frecuencia descendente.
  final List<MapEntry<String, int>> frictionRanking;

  const MonthlyData({
    required this.monthStart,
    required this.nutritionByDay,
    required this.sessionDays,
    required this.frictionDays,
    required this.weighInDays,
    required this.totalMinutes,
    required this.sessionsCount,
    required this.frictionRanking,
  });

  DateTime get nextMonth => DateTime(monthStart.year, monthStart.month + 1);

  /// Días del mes (parcial si es el mes en curso) con algún check-in.
  int get checkedDays => nutritionByDay.length;

  /// Días pintados de verde (plan cumplido).
  int get greenDays => nutritionByDay.values
      .where((l) => l == NutritionLevel.green)
      .length;

  /// Consistencia nutricional: verdes / días con check-in (0–100).
  int get nutritionConsistencyPercent =>
      checkedDays == 0 ? 0 : ((greenDays / checkedDays) * 100).round();

  bool isWithinMonth(DateTime day) =>
      !day.isBefore(monthStart) && day.isBefore(nextMonth);

  factory MonthlyData.compute({
    required DateTime monthStart,
    required List<SessionEntry> sessions,
    required List<WeightRecord> weights,
    required List<NutritionCheck> checks,
    required List<FrictionLog> frictions,
  }) {
    final start = monthStart.dateOnly;
    final end = DateTime(start.year, start.month + 1);

    bool inMonth(DateTime d) => !d.isBefore(start) && d.isBefore(end);

    // ---- Nutrición ----
    final nutritionByDay = <DateTime, NutritionLevel>{
      for (final e in WeekMath.checksByDay(checks).entries)
        if (inMonth(e.key)) e.key: e.value,
    };

    // ---- Sesiones ----
    var totalMinutes = 0;
    var sessionsCount = 0;
    final sessionDays = <DateTime>{};
    for (final s in sessions) {
      if (!inMonth(s.day)) continue;
      totalMinutes += s.durationMinutes;
      sessionsCount++;
      sessionDays.add(s.day.dateOnly);
    }

    // ---- Fricciones ----
    final frictionDays = <DateTime>{};
    final counts = <String, int>{};
    for (final f in frictions) {
      if (!inMonth(f.day)) continue;
      frictionDays.add(f.day.dateOnly);
      final label = f.effectiveLabel.trim();
      if (label.isEmpty) continue;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final ranking = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // ---- Pesajes ----
    final weighInDays = <DateTime>{
      for (final w in weights)
        if (inMonth(w.date)) w.date.dateOnly,
    };

    return MonthlyData(
      monthStart: start,
      nutritionByDay: nutritionByDay,
      sessionDays: sessionDays,
      frictionDays: frictionDays,
      weighInDays: weighInDays,
      totalMinutes: totalMinutes,
      sessionsCount: sessionsCount,
      frictionRanking: ranking,
    );
  }
}
