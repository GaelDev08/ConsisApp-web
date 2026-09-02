import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/domain/entities/goal.dart';
import 'package:consis_app/domain/entities/goal_type.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/goal_settings_sheet.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carrusel horizontal de metas: tap = poner esa meta EN FOCO.
///
/// Mantiene la regla del hiperenfoque: la UI siempre muestra una sola,
/// pero cambiar es un tap y todo el dashboard reacciona.
class GoalSelector extends ConsumerWidget {
  const GoalSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsStreamProvider).valueOrNull ?? const <Goal>[];
    final activeId = ref.watch(activeGoalIdProvider);

    if (goals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: OutlinedButton.icon(
          onPressed: () => showGoalSettingsSheet(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Crear primera meta'),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: goals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final g = goals[i];
          final isActive = g.id == activeId;

          return GestureDetector(
            onTap: () async {
              final settings =
                  ref.read(appSettingsStreamProvider).valueOrNull;
              if (settings == null) return;
              await ref
                  .read(appSettingsRepositoryProvider)
                  .save(settings.copyWith(activeGoalId: g.id));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.violet.withValues(alpha: 0.16)
                    : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isActive
                      ? AppColors.violet.withValues(alpha: 0.7)
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconFor(g.type),
                      size: 14,
                      color: isActive
                          ? AppColors.violet
                          : _colorFor(g.type).withValues(alpha: 0.75)),
                  const SizedBox(width: 6),
                  Text(
                    g.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w500,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle_rounded,
                        size: 13, color: AppColors.emerald),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

IconData _iconFor(GoalType type) {
  switch (type) {
    case GoalType.timeAccumulated:
      return Icons.code_rounded;
    case GoalType.fitness:
      return Icons.fitness_center_rounded;
    case GoalType.fasting:
      return Icons.hourglass_bottom_rounded;
    case GoalType.custom:
      return Icons.star_border_rounded;
  }
}

Color _colorFor(GoalType type) {
  switch (type) {
    case GoalType.timeAccumulated:
      return AppColors.violet;
    case GoalType.fitness:
      return AppColors.cyan;
    case GoalType.fasting:
      return AppColors.amber;
    case GoalType.custom:
      return AppColors.emerald;
  }
}
