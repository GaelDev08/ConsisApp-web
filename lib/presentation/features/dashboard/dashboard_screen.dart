import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/greeting.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/goal_type.dart';
import 'package:consis_app/presentation/features/analytics/monthly_screen.dart';
import 'package:consis_app/presentation/features/dashboard/dashboard_data.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/friction_nudge_card.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/goal_selector.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/goal_settings_sheet.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/nutrition_section.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/weigh_in_card.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/weekly_goal_card.dart';
import 'package:consis_app/presentation/security/security_sheet.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/fasting_card.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard principal de ConsisApp (Fase 2).
///
/// Layout responsive: columna centrada con ancho máximo en pantallas
/// anchas (Flutter Web desktop) y scroll vertical natural en móvil.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardDataProvider);

    return Scaffold(
      body: SafeArea(
        child: data == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.violet),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                    child: _DashboardContent(data: data),
                  ),
                ),
              ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final DashboardData data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoal = ref.watch(activeGoalProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 14),
        const GoalSelector(),
        const SizedBox(height: 18),
        if (activeGoal != null && activeGoal.type == GoalType.fasting)
          FastingCard(goal: activeGoal)
        else
          WeeklyGoalCard(data: data),
        // Regla de dominio: nutrición/peso solo para metas de salud
        // (fitness · ayuno · custom con toggle activado).
        if (activeGoal?.requiresNutritionTracking ?? false) ...[
          const SizedBox(height: 16),
          NutritionSection(data: data),
        ],
        if (activeGoal?.requiresWeightTracking ?? false) ...[
          const SizedBox(height: 16),
          WeighInCard(data: data),
        ],
        if (!data.todayHasActivity) ...[
          const SizedBox(height: 16),
          const FrictionNudgeCard(),
        ],
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  String get _dateLabel {
    final raw = formatDateEs(DateTime.now());
    return '${raw[0].toUpperCase()}${raw.substring(1)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileStreamProvider).valueOrNull;
    final greeting = Greeting.forNow(name: profile?.name);
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text(_dateLabel,
                  style: text.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Editar meta',
          onPressed: () => showGoalSettingsSheet(context),
          icon: const Icon(Icons.tune_rounded),
          color: AppColors.textSecondary,
        ),
        IconButton(
          tooltip: 'Consistencia mensual',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MonthlyScreen(),
            ),
          ),
          icon: const Icon(Icons.calendar_month_rounded),
          color: AppColors.textSecondary,
        ),
        IconButton(
          tooltip: 'Seguridad',
          onPressed: () => showSecuritySheet(context),
          icon: const Icon(Icons.lock_outline_rounded),
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppColors.goalGradient,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.center_focus_strong_rounded,
              color: Colors.white, size: 26),
        ),
      ],
    );
  }
}
