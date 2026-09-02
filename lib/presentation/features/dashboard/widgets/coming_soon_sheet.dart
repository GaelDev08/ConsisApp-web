import 'package:consis_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Sheet informativa para los flujos que llegan en Fase 3
/// (modales de registro rápido de minutos/peso/motivos).
void showComingSoonSheet(BuildContext context, String flowName) {
  final text = Theme.of(context).textTheme;

  showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, color: AppColors.amber, size: 38),
            const SizedBox(height: 12),
            Text(flowName, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Este flujo se implementa en la Fase 3:\nmodales de registro rápido.',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    },
  );
}
