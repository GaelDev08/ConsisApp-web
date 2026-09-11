import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/domain/entities/goal.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/fasting_log_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tarjeta dedicada cuando la meta activa es de AYUNO intermitente.
/// Registro manual por hora de inicio y hora de fin por día.
class FastingCard extends ConsumerWidget {
  final Goal goal;

  const FastingCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = goal.fasting;
    final fastGoal = cfg?.fastHours ?? 16;
    final windowH = cfg?.windowHours ?? 8;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_bottom_rounded,
                  color: AppColors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Ayuno $fastGoal/$windowH',
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Meta $fastGoal h',
                  style: text.labelSmall?.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Registra tus ayunos diarios indicando la hora de inicio y fin.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => showFastingLogSheet(context),
            icon: const Icon(Icons.more_time_rounded),
            label: const Text('Registrar ayuno del día'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
