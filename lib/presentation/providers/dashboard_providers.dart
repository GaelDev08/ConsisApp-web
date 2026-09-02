import 'package:consis_app/domain/entities/app_settings.dart';
import 'package:consis_app/domain/entities/friction_log.dart';
import 'package:consis_app/domain/entities/goal.dart';
import 'package:consis_app/domain/entities/goal_type.dart';
import 'package:consis_app/domain/entities/nutrition_check.dart';
import 'package:consis_app/core/constants/goal_defaults.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/domain/entities/user_profile.dart';
import 'package:consis_app/domain/entities/weight_record.dart';
import 'package:consis_app/presentation/features/dashboard/dashboard_data.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams reactivos por colección (Hive → entidades de dominio).

final appSettingsStreamProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(appSettingsRepositoryProvider).watch(),
);

/// Perfil del usuario (nombre para el saludo dinámico, etc.).
final userProfileStreamProvider = StreamProvider<UserProfile>(
  (ref) => ref.watch(userProfileRepositoryProvider).watch(),
);

final goalsStreamProvider = StreamProvider<List<Goal>>(
  (ref) => ref.watch(goalRepositoryProvider).watchAll(),
);

final sessionsStreamProvider = StreamProvider<List<SessionEntry>>(
  (ref) => ref.watch(sessionEntryRepositoryProvider).watchAll(),
);

final weightRecordsStreamProvider = StreamProvider<List<WeightRecord>>(
  (ref) => ref.watch(weightRecordRepositoryProvider).watchAll(),
);

final nutritionChecksStreamProvider = StreamProvider<List<NutritionCheck>>(
  (ref) => ref.watch(nutritionCheckRepositoryProvider).watchAll(),
);

final frictionsStreamProvider = StreamProvider<List<FrictionLog>>(
  (ref) => ref.watch(frictionLogRepositoryProvider).watchAll(),
);

/// Ayuno EN CURSO de la meta activa (para el temporizador en vivo).
/// Null si no hay ninguno abierto.
final activeFastEntryProvider = Provider<SessionEntry?>((ref) {
  final goal = ref.watch(activeGoalProvider);
  final sessions = ref.watch(sessionsStreamProvider).valueOrNull;
  if (goal == null || sessions == null) return null;

  for (final s in sessions.reversed) {
    if (s.goalId == goal.id && s.isActiveFast) return s;
  }
  return null;
});

/// Meta EN FOCO del carrusel: la marcada en ajustes; si no hay,
/// la primera disponible. Null si aún no existen metas.
final activeGoalProvider = Provider<Goal?>((ref) {
  final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
  final goals = ref.watch(goalsStreamProvider).valueOrNull;
  if (goals == null || goals.isEmpty) return null;

  final wanted = settings?.activeGoalId ?? '';
  for (final g in goals) {
    if (!g.archived && g.id == wanted) return g;
  }
  return goals.firstWhere((g) => !g.archived, orElse: () => goals.first);
});

/// Id de la meta activa ('' si ninguna) — atajo para formularios.
final activeGoalIdProvider = Provider<String>(
  (ref) => ref.watch(activeGoalProvider)?.id ?? '',
);

/// View-model agregado del dashboard (meta EN FOCO).
///
/// Emite `null` mientras algún stream está cargando; cualquier cambio en
/// cualquier caja re-emite automáticamente.
final dashboardDataProvider = Provider<DashboardData?>((ref) {
  final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
  final activeGoal = ref.watch(activeGoalProvider);
  final sessions = ref.watch(sessionsStreamProvider).valueOrNull;
  final weights = ref.watch(weightRecordsStreamProvider).valueOrNull;
  final checks = ref.watch(nutritionChecksStreamProvider).valueOrNull;
  final frictions = ref.watch(frictionsStreamProvider).valueOrNull;

  if (settings == null ||
      sessions == null ||
      weights == null ||
      checks == null ||
      frictions == null) {
    return null;
  }

  // Sin meta activa aún: progreso vacío pero pantalla estable.
  final scopedSessions = activeGoal == null
      ? const <SessionEntry>[]
      : sessions.where((s) => s.goalId == activeGoal.id).toList(growable: false);
  final scopedFrictions = activeGoal == null
      ? const <FrictionLog>[]
      : frictions
          .where((f) => f.goalId == activeGoal.id)
          .toList(growable: false);

  final targetInfo = activeGoal == null ? null : _targetFor(activeGoal);

  return DashboardData.compute(
    goalTitle: activeGoal?.title ?? 'Sin meta activa',
    targetMinutes: targetInfo?.target ?? 0,
    unitShort: targetInfo?.unit ?? 'min',
    weighInWeekday: settings.weighInWeekday,
    sessions: scopedSessions,
    weights: weights,
    checks: checks,
    frictions: scopedFrictions,
    now: DateTime.now(),
  );
});

/// Objetivo + etiqueta corta de unidad según el tipo de meta.
({int target, String unit}) _targetFor(Goal goal) {
  switch (goal.type) {
    case GoalType.fasting:
      return (target: goal.fasting?.fastHours ?? 0, unit: 'h');
    case GoalType.custom:
      return (target: goal.targetValue, unit: goalUnitShort(goal.unit));
    default:
      return (target: goal.targetValue, unit: 'min');
  }
}
