import 'package:consis_app/presentation/features/analytics/monthly_data.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agregado mensual reactivo. `null` mientras cargan los streams.
///
/// El argumento debe ser el primer día del mes (normalizado).
final monthlyDataProvider =
    Provider.autoDispose.family<MonthlyData?, DateTime>((ref, monthStart) {
  final sessions = ref.watch(sessionsStreamProvider).valueOrNull;
  final weights = ref.watch(weightRecordsStreamProvider).valueOrNull;
  final checks = ref.watch(nutritionChecksStreamProvider).valueOrNull;
  final frictions = ref.watch(frictionsStreamProvider).valueOrNull;

  if (sessions == null ||
      weights == null ||
      checks == null ||
      frictions == null) {
    return null;
  }

  return MonthlyData.compute(
    monthStart: monthStart,
    sessions: sessions,
    weights: weights,
    checks: checks,
    frictions: frictions,
  );
});

