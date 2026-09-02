import 'package:consis_app/core/utils/datetime_x.dart';
import 'package:consis_app/domain/entities/friction_log.dart';
import 'package:consis_app/domain/entities/nutrition_check.dart';
import 'package:consis_app/domain/entities/nutrition_level.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/domain/entities/weight_record.dart';
import 'package:consis_app/domain/services/week_math.dart';

/// Estado del pesaje oficial para el dashboard.
enum WeighInStatus {
  /// Ya se registró el pesaje de esta semana. ✔
  done,

  /// Hoy es el día oficial (o ya pasó) y falta registrar → alerta visible.
  dueToday,

  /// Aún no llega el día oficial de esta semana.
  scheduled,
}

/// View-model inmutable del dashboard, ensamblado a partir de las
/// entidades del dominio. Todos los cálculos semanales usan semanas
/// lunes-domingo y días normalizados a medianoche.
class DashboardData {
  final String goalName;

  /// Etiqueta corta de la unidad de la meta ('min', 'págs', 'h', 'ses').
  final String unitShort;

  final int targetMinutes;
  final int weekMinutes;
  final int sessionsThisWeek;
  final int activeDaysThisWeek;
  final bool todayHasActivity;

  final NutritionLevel? todayNutrition;

  /// Índice 0 = lunes … 6 = domingo; null = día sin check-in.
  final List<NutritionLevel?> weekNutrition;

  final WeighInStatus weighInStatus;
  final double? lastWeightKg;
  final double? weightDeltaVsPrevWeek;
  final DateTime nextWeighInDate;

  final int frictionsThisWeek;

  const DashboardData({
    required this.goalName,
    this.unitShort = 'min',
    required this.targetMinutes,
    required this.weekMinutes,
    required this.sessionsThisWeek,
    required this.activeDaysThisWeek,
    required this.todayHasActivity,
    required this.todayNutrition,
    required this.weekNutrition,
    required this.weighInStatus,
    required this.lastWeightKg,
    required this.weightDeltaVsPrevWeek,
    required this.nextWeighInDate,
    required this.frictionsThisWeek,
  });

  double get progressRatio =>
      targetMinutes <= 0 ? 0 : (weekMinutes / targetMinutes).clamp(0.0, 1.0);

  int get remainingMinutes =>
      (targetMinutes - weekMinutes).clamp(0, targetMinutes);

  int get progressPercent => (progressRatio * 100).round();

  factory DashboardData.compute({
    required String goalTitle,
    required int targetMinutes,
    String? unitShort,
    required int weighInWeekday,
    required List<SessionEntry> sessions,
    required List<WeightRecord> weights,
    required List<NutritionCheck> checks,
    required List<FrictionLog> frictions,
    required DateTime now,
  }) {
    final today = now.dateOnly;
    final monday = WeekMath.mondayOf(now);

    // ---- Minutos / sesiones de la semana ----
    final weekSessions = sessions
        .where((s) => WeekMath.isWithinWeekOf(s.day, now))
        .toList(growable: false);
    final weekMinutes =
        weekSessions.fold<int>(0, (total, s) => total + s.durationMinutes);
    final activeDaysThisWeek = WeekMath.distinctDays(weekSessions)
        .where((d) => WeekMath.isWithinWeekOf(d, now))
        .length;
    final todayHasActivity =
        sessions.any((s) => s.day.dateOnly.isSameDayAs(today));

    // ---- Semáforo nutricional ----
    final checksByDay = WeekMath.checksByDay(checks);
    final weekNutrition = List<NutritionLevel?>.generate(
      7,
      (i) => checksByDay[monday.add(Duration(days: i))],
      growable: false,
    );
    final todayNutrition = checksByDay[today];

    // ---- Pesaje semanal ----
    final sortedWeights = [...weights]..sort((a, b) => a.date.compareTo(b.date));
    final weighedThisWeek =
        sortedWeights.any((w) => WeekMath.isWithinWeekOf(w.date, now));
    final officialThisWeek =
        monday.add(Duration(days: weighInWeekday - 1));

    WeighInStatus status;
    DateTime nextDate;
    if (!weighedThisWeek && !today.isBefore(officialThisWeek)) {
      // Es (o ya pasó) el día oficial y falta registrar: recordatorio activo.
      status = WeighInStatus.dueToday;
      nextDate = today;
    } else if (!weighedThisWeek) {
      status = WeighInStatus.scheduled;
      nextDate = officialThisWeek;
    } else {
      status = WeighInStatus.done;
      final dd = WeekMath.daysUntilWeekday(today, weighInWeekday);
      nextDate = today.add(Duration(days: dd == 0 ? 7 : dd));
    }

    double? lastWeightKg;
    for (final w in sortedWeights.reversed) {
      lastWeightKg = w.weightKg;
      break;
    }
    double? currentWeekKg;
    for (final w in sortedWeights.reversed) {
      if (WeekMath.isWithinWeekOf(w.date, now)) {
        currentWeekKg = w.weightKg;
        break;
      }
    }
    double? previousKg;
    for (final w in sortedWeights.reversed) {
      if (w.date.dateOnly.isBefore(monday)) {
        previousKg = w.weightKg;
        break;
      }
    }
    final delta = currentWeekKg != null && previousKg != null
        ? currentWeekKg - previousKg
        : null;

    // ---- Fricciones de la semana ----
    final frictionsThisWeek =
        frictions.where((f) => WeekMath.isWithinWeekOf(f.day, now)).length;

    return DashboardData(
      goalName: goalTitle,
      targetMinutes: targetMinutes,
      unitShort: unitShort ?? 'min',
      weekMinutes: weekMinutes,
      sessionsThisWeek: weekSessions.length,
      activeDaysThisWeek: activeDaysThisWeek,
      todayHasActivity: todayHasActivity,
      todayNutrition: todayNutrition,
      weekNutrition: weekNutrition,
      weighInStatus: status,
      lastWeightKg: lastWeightKg ?? currentWeekKg,
      weightDeltaVsPrevWeek: delta,
      nextWeighInDate: nextDate,
      frictionsThisWeek: frictionsThisWeek,
    );
  }
}
