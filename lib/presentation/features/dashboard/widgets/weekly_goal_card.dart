import 'dart:math' as math;

import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/domain/entities/goal_type.dart';
import 'package:consis_app/presentation/features/dashboard/dashboard_data.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/composite_log_sheet.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/quantity_log_sheet.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/quick_log_sheet.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tarjeta héroe del dashboard: anillo de progreso interactivo
/// (minutos completados vs meta semanal) con gradiente violeta→cyan.
///
/// Interactividad: tocar el centro cicla el modo de lectura
/// minutos → porcentaje → restantes.
class WeeklyGoalCard extends ConsumerStatefulWidget {
  final DashboardData data;

  const WeeklyGoalCard({super.key, required this.data});

  @override
  ConsumerState<WeeklyGoalCard> createState() => _WeeklyGoalCardState();
}

enum _CenterMode { minutes, percent, remaining }

class _WeeklyGoalCardState extends ConsumerState<WeeklyGoalCard> {
  static const List<_CenterMode> _modes = _CenterMode.values;
  _CenterMode _mode = _CenterMode.minutes;

  void _cycleMode() {
    setState(() {
      _mode = _modes[(_mode.index + 1) % _modes.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: _cycleMode,
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: AppColors.goalGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerRow(data, text),
              const SizedBox(height: 18),
              _ring(data, text),
              const SizedBox(height: 18),
              _statsRow(data),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openLogSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Registrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre el formulario correcto según el TIPO de la meta activa.
  void _openLogSheet(BuildContext context) {
    final goal = ref.read(activeGoalProvider);
    if (goal == null) return;

    switch (goal.type) {
      case GoalType.timeAccumulated:
        showQuickLogSheet(context, data: widget.data);
      case GoalType.fitness:
        showCompositeLogSheet(context);
      case GoalType.custom:
        showQuantityLogSheet(context);
      case GoalType.fasting:
        // El flujo del ayuno es la tarjeta dedicada del dashboard.
        break;
    }
  }

  Widget _headerRow(DashboardData data, TextTheme text) {
    return Row(
      children: [
        Expanded(
          child: Text('Meta semanal',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        _GoalPill(label: data.goalName),
      ],
    );
  }

  Widget _ring(DashboardData data, TextTheme text) {
    return Center(
      child: SizedBox(
        width: 172,
        height: 172,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: data.progressRatio),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, animatedProgress, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(172, 172),
                  painter:
                      _ProgressRingPainter(progress: animatedProgress),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _centerValue(data, text),
                    const SizedBox(height: 2),
                    Text(
                      _centerLabel(data),
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toca para cambiar vista',
                      style: text.labelSmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statsRow(DashboardData data) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.local_fire_department_rounded,
            value: '${data.activeDaysThisWeek}/7',
            label: 'días activos',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.fitness_center_rounded,
            value: '${data.sessionsThisWeek}',
            label: 'sesiones',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: data.todayHasActivity
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            value: data.todayHasActivity ? 'Sí' : 'No',
            label: 'hoy',
            highlight: data.todayHasActivity,
          ),
        ),
      ],
    );
  }

  Widget _centerValue(DashboardData data, TextTheme text) {
    switch (_mode) {
      case _CenterMode.minutes:
        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: '${data.weekMinutes}',
                style: text.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
              ),
              TextSpan(
                text: ' / ${data.targetMinutes}',
                style:
                    text.titleMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      case _CenterMode.percent:
        return Text(
          '${data.progressPercent}%',
          style: text.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
        );
      case _CenterMode.remaining:
        return Text(
          '${data.remainingMinutes}',
          style: text.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
        );
    }
  }

  String _centerLabel(DashboardData data) {
    switch (_mode) {
      case _CenterMode.minutes:
        return '${data.unitShort} esta semana';
      case _CenterMode.percent:
        return 'de tu meta';
      case _CenterMode.remaining:
        return '${data.unitShort} restantes';
    }
  }
}

class _GoalPill extends StatelessWidget {
  final String label;

  const _GoalPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.center_focus_strong_rounded,
              size: 13, color: AppColors.violet),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.violet,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? AppColors.emerald : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 15, color: accent.withValues(alpha: 0.85)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Track sutil + arco Sweep violeta→cyan + glow en el extremo.
class _ProgressRingPainter extends CustomPainter {
  final double progress;

  _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.border;
    canvas.drawCircle(center, radius, trackPaint);

    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;

    const gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
      colors: [AppColors.violet, AppColors.cyan],
    );
    final shader = gradient.createShader(rect);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..shader = shader;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * p, false, arcPaint);

    final angle = -math.pi / 2 + math.pi * 2 * p;
    canvas.drawCircle(
      center + Offset(math.cos(angle), math.sin(angle)) * radius,
      stroke / 2,
      Paint()..color = AppColors.cyan.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}


