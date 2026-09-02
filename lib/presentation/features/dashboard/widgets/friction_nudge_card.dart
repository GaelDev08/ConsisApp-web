import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/friction_log_sheet.dart';
import 'package:flutter/material.dart';

/// Nudge de hiperenfoque: aparece solo cuando HOY aún no hay actividad,
/// invitando a dejar un motivo en la bitácora de fricciones (Fase 3).
class FrictionNudgeCard extends StatelessWidget {
  const FrictionNudgeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology_alt_rounded,
              color: AppColors.coral.withValues(alpha: 0.9), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Hoy no tocó la meta?',
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Deja el motivo y detecta tus patrones.',
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => showFrictionLogSheet(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.coral,
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: const Text('Motivo'),
          ),
        ],
      ),
    );
  }
}
