import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/presentation/features/dashboard/dashboard_data.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/weight_log_sheet.dart';
import 'package:flutter/material.dart';

/// Tarjeta del control de peso semanal según [WeighInStatus]:
/// - done: confirmación esmeralda con kg + delta vs semana anterior.
/// - dueToday: alerta ámbar "¡Día de pesaje!".
/// - scheduled: próximo pesaje programado.
class WeighInCard extends StatelessWidget {
  final DashboardData data;

  const WeighInCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    switch (data.weighInStatus) {
      case WeighInStatus.done:
        return _card(context, accent: AppColors.emerald);
      case WeighInStatus.dueToday:
        return _card(context, accent: AppColors.amber);
      case WeighInStatus.scheduled:
        return _card(context, accent: AppColors.textSecondary);
    }
  }

  Widget _card(BuildContext context, {required Color accent}) {
    final text = Theme.of(context).textTheme;
    final trailing = _trailing(context, text);

    final (icon, title, subtitle) = switch (data.weighInStatus) {
      WeighInStatus.done => (
          Icons.check_circle_rounded,
          'Pesaje registrado',
          _doneSubtitle(),
        ),
      WeighInStatus.dueToday => (
          Icons.monitor_weight_rounded,
          '¡Día de pesaje!',
          'Registra tu peso oficial de la semana',
        ),
      WeighInStatus.scheduled => (
          Icons.event_available_rounded,
          'Próximo pesaje',
          formatDateEs(data.nextWeighInDate),
        ),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  String? _doneSubtitle() {
    final kg = data.lastWeightKg;
    if (kg == null) return null;
    final delta = data.weightDeltaVsPrevWeek;
    final deltaText = delta == null
        ? ''
        : ' · ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} vs anterior';
    return '${kg.toStringAsFixed(1)} kg$deltaText';
  }

  Widget? _trailing(BuildContext context, TextTheme text) {
    switch (data.weighInStatus) {
      case WeighInStatus.done:
        return Text('Semana ✓',
            style: text.labelMedium?.copyWith(
                color: AppColors.emerald, fontWeight: FontWeight.w600));
      case WeighInStatus.dueToday:
        return FilledButton(
          onPressed: () => showWeightLogSheet(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: const Color(0xFF2B1A02),
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          child: const Text('Registrar'),
        );
      case WeighInStatus.scheduled:
        final kg = data.lastWeightKg;
        if (kg == null) return null;
        return Text('${kg.toStringAsFixed(1)} kg',
            style: text.labelLarge?.copyWith(color: AppColors.textSecondary));
    }
  }
}
