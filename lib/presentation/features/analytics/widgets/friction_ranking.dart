import 'package:consis_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Ranking de motivos recurrentes del mes con barras proporcionales.
class FrictionRanking extends StatelessWidget {
  final List<MapEntry<String, int>> ranking;

  const FrictionRanking({super.key, required this.ranking});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (ranking.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppColors.emerald, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Cero fricciones registradas este mes!',
                style:
                    text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final maxCount = ranking.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in ranking.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}×',
                        style: text.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.coral)),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor:
                        (entry.value / (maxCount < 1 ? 1 : maxCount))
                            .clamp(0.08, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.coral.withValues(alpha: 0.55),
                          AppColors.coral,
                        ]),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (ranking.length > 8)
          Text(
            '+${ranking.length - 8} motivos más…',
            style: text.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
      ],
    );
  }
}
