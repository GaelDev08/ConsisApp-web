import 'package:consis_app/core/constants/goal_defaults.dart';
import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/goal_type.dart';
import 'package:consis_app/presentation/features/dashboard/dashboard_data.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/sheet_shell.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const List<int> _presets = [15, 30, 45, 60];

/// Modal "2 taps": primer tap elige preset, segundo confirma.
/// El stepper permite ajuste fino en pasos de 5 minutos.
Future<void> showQuickLogSheet(
  BuildContext context, {
  required DashboardData data,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _QuickLogSheet(data: data),
  );
}

class _QuickLogSheet extends ConsumerStatefulWidget {
  final DashboardData data;

  const _QuickLogSheet({required this.data});

  @override
  ConsumerState<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<_QuickLogSheet> {
  int _minutes = 30;
  int? _selectedPreset;
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedTags = {};

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now, // no se permiten sesiones futuras
      helpText: 'Fecha de la sesión',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _selectPreset(int value) {
    setState(() {
      _minutes = value;
      _selectedPreset = value;
    });
  }

  void _adjust(int delta) {
    setState(() {
      _minutes = (_minutes + delta).clamp(1, 600);
      _selectedPreset = _presets.contains(_minutes) ? _minutes : null;
    });
  }

  Future<void> _save() async {
    final goalId = ref.read(activeGoalIdProvider);
    if (goalId.isEmpty) return;

    final repo = ref.read(sessionEntryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final minutes = _minutes;
    final day = _selectedDate;

    await repo.addSimple(
      goalId: goalId,
      day: day,
      minutes: minutes,
      tags: _selectedTags.toList(growable: false),
    );

    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.emerald),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Sesión registrada · $minutes min · ${formatSmartDateEs(day)}'),
        ),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final goal = ref.watch(activeGoalProvider);
    final showTags = goal?.type == GoalType.timeAccumulated;
    final tagOptions = (goal != null && goal.contextTags.isNotEmpty)
        ? goal.contextTags
        : kStudyContextTagPresets;

    return SheetShell(
      title: 'Registrar sesión',
      subtitle:
          '${data.goalName} · ${data.weekMinutes}/${data.targetMinutes} min esta semana',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetDateField(
            label: '📅 ${formatSmartDateEs(_selectedDate)}',
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          if (showTags) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tagOptions)
                  _TagChip(
                    label: tag,
                    selected: _selectedTags.contains(tag),
                    onTap: () => setState(() {
                      if (_selectedTags.contains(tag)) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              for (final preset in _presets) ...[
                Expanded(
                  child: _PresetButton(
                    value: preset,
                    selected: _selectedPreset == preset,
                    onTap: () => _selectPreset(preset),
                  ),
                ),
                if (preset != _presets.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _Stepper(minutes: _minutes, onAdjust: _adjust),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text('Registrar $_minutes min',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.14)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.violet.withValues(alpha: 0.7)
                : AppColors.border,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary)),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppColors.violet : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 58,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.14)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.violet.withValues(alpha: 0.7)
                : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('+$value',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: accent)),
            const Text('min',
                style:
                    TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onAdjust;

  const _Stepper({required this.minutes, required this.onAdjust});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepButton(icon: Icons.remove_rounded, onTap: () => onAdjust(-5)),
          Column(
            children: [
              Text('$minutes',
                  style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: -1)),
              Text('minutos',
                  style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
            ],
          ),
          _StepButton(icon: Icons.add_rounded, onTap: () => onAdjust(5)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}


