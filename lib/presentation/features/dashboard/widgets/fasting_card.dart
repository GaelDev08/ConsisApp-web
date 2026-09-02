import 'dart:async';

import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/fasting_calculator.dart';
import 'package:consis_app/domain/entities/goal.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tarjeta dedicada cuando la meta activa es de AYUNO intermitente.
///
/// Temporizador en tiempo real: inicia el ayuno, corre cada segundo y
/// finaliza persistiendo la duración continua lograda.
class FastingCard extends ConsumerStatefulWidget {
  final Goal goal;

  const FastingCard({super.key, required this.goal});

  @override
  ConsumerState<FastingCard> createState() => _FastingCardState();
}

class _FastingCardState extends ConsumerState<FastingCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTicker());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    _ticker?.cancel();
    final active = ref.read(activeFastEntryProvider);
    if (active != null) {
      // Tick por segundo para refrescar el cronómetro en vivo.
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _start() async {
    final repo = ref.read(sessionEntryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();

    await repo.add(
      SessionEntry(
        id: repo.newId(),
        goalId: widget.goal.id,
        day: now,
        fastingStartAt: now,
        createdAt: now,
      ),
    );

    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.cyan),
        const SizedBox(width: 10),
        Text('Ayuno iniciado · meta ${widget.goal.fasting?.fastHours ?? 16} h'),
      ]),
    ));
  }

  Future<void> _finish(SessionEntry active) async {
    final repo = ref.read(sessionEntryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final endAt = DateTime.now();
    final total = active.fastingElapsed(now: endAt);

    await repo.finishFasting(entryId: active.id, endAt: endAt);

    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded,
            size: 18, color: AppColors.emerald),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
              'Ayuno completado · ${FastingCalculator.formatDuration(total)}'),
        ),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeFastEntryProvider, (_, __) => _syncTicker());

    final active = ref.watch(activeFastEntryProvider);
    final cfg = widget.goal.fasting;
    final fastGoal = cfg?.fastHours ?? 16;
    final windowH = cfg?.windowHours ?? 8;

    final elapsed = active?.fastingElapsed() ?? Duration.zero;
    final reached = FastingCalculator.reachedGoal(
        elapsed: elapsed, fastHoursGoal: fastGoal);
    final progress = (elapsed.inMinutes / (fastGoal * 60)).clamp(0.0, 1.0);

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
              Text(
                active == null
                    ? 'Inactivo'
                    : (reached ? '¡META CUMPLIDA!' : 'EN CURSO'),
                style: text.labelSmall?.copyWith(
                  color: reached
                      ? AppColors.emerald
                      : active == null
                          ? AppColors.textMuted
                          : AppColors.cyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              FastingCalculator.formatDuration(elapsed),
              style: text.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              reached
                  ? '¡Objetivo de $fastGoal h cumplido!'
                  : 'Objetivo: $fastGoal h continuas',
              style: text.bodySmall?.copyWith(
                color:
                    reached ? AppColors.emerald : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                  reached ? AppColors.emerald : AppColors.cyan),
            ),
          ),
          const SizedBox(height: 18),
          active == null
              ? FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar ayuno'),
                )
              : FilledButton.tonalIcon(
                  onPressed: () => _finish(active),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Finalizar ayuno'),
                ),
        ],
      ),
    );
  }
}

