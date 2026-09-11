import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/fasting_calculator.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card que muestra el historial de sesiones registradas 1 por 1
/// para la meta actualmente en foco.
class SessionHistoryList extends ConsumerWidget {
  const SessionHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoal = ref.watch(activeGoalProvider);
    if (activeGoal == null) return const SizedBox.shrink();

    final sessionsAsync = ref.watch(sessionsStreamProvider);
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historial de sesiones',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Icon(Icons.history_rounded, size: 20, color: AppColors.violet),
            ],
          ),
          const SizedBox(height: 12),
          sessionsAsync.when(
            data: (sessions) {
              final goalSessions = sessions
                  .where((s) => s.goalId == activeGoal.id)
                  .toList()
                ..sort((a, b) => b.day.compareTo(a.day));

              if (goalSessions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Aún no hay sesiones registradas.',
                      style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (final session in goalSessions) ...[
                    _SessionTile(session: session),
                    if (session != goalSessions.last)
                      const Divider(height: 1, color: AppColors.border),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.violet),
              ),
            ),
            error: (err, _) => Text(
              'Error al cargar sesiones: $err',
              style: text.bodySmall?.copyWith(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  final SessionEntry session;

  const _SessionTile({required this.session});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar sesión',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Â¿Deseas eliminar este registro de la meta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(sessionEntryRepositoryProvider).deleteById(session.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    String subtitleText = '';
    if (session.isFasting) {
      if (session.fastingStartAt != null && session.fastingEndAt != null) {
        final startStr =
            '${session.fastingStartAt!.hour.toString().padLeft(2, '0')}:${session.fastingStartAt!.minute.toString().padLeft(2, '0')}';
        final endStr =
            '${session.fastingEndAt!.hour.toString().padLeft(2, '0')}:${session.fastingEndAt!.minute.toString().padLeft(2, '0')}';
        subtitleText = 'Ayuno $startStr - $endStr (${FastingCalculator.formatDuration(Duration(minutes: session.durationMinutes))})';
      } else {
        subtitleText = 'Ayuno ${session.durationMinutes} min';
      }
    } else if (session.activities.isNotEmpty) {
      subtitleText = session.activities
          .map((a) => '${a.name} (${a.minutes}m)')
          .join(', ');
    } else if (session.tags.isNotEmpty) {
      subtitleText = 'Categorías: ${session.tags.join(', ')}';
    } else if ((session.quantity ?? 0) > 0) {
      subtitleText = 'Cantidad: ${session.quantity}';
    } else {
      subtitleText = '${session.durationMinutes} min acumulados';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      dense: true,
      title: Text(
        formatSmartDateEs(session.day),
        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitleText,
        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (session.durationMinutes > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${session.durationMinutes} min',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.violet,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.textMuted),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
    );
  }
}
