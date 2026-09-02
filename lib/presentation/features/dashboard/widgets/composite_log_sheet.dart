import 'package:consis_app/core/constants/goal_defaults.dart';
import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/activity_entry.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/sheet_shell.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal de sesión FITNESS compuesta multiactividad:
/// selecciona actividades y ajusta los minutos de cada una
/// ("Running 30 + Caminata 10") en un solo registro.
Future<void> showCompositeLogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CompositeLogSheet(),
  );
}

class _CompositeLogSheet extends ConsumerStatefulWidget {
  const _CompositeLogSheet();

  @override
  ConsumerState<_CompositeLogSheet> createState() => _CompositeLogSheetState();
}

class _CompositeLogSheetState extends ConsumerState<_CompositeLogSheet> {
  /// Índice en kFitnessActivityPresets → minutos asignados.
  final Map<int, int> _selected = {};
  DateTime _selectedDate = DateTime.now();
  String? _error;

  int get _total =>
      _selected.values.fold(0, (sum, m) => sum + m);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'Fecha de la sesión',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _toggle(int index) {
    setState(() {
      if (_selected.containsKey(index)) {
        _selected.remove(index);
      } else {
        _selected[index] = 10;
      }
      _error = null;
    });
  }

  void _adjust(int index, int delta) {
    setState(() {
      final v = ((_selected[index] ?? 10) + delta).clamp(1, 600);
      _selected[index] = v;
    });
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      setState(() => _error = 'Selecciona al menos una actividad');
      return;
    }

    final goalId = ref.read(activeGoalIdProvider);
    if (goalId.isEmpty) return;

    final repo = ref.read(sessionEntryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final activities = <ActivityEntry>[];
    var total = 0;
    for (final entry in _selected.entries) {
      final name = kFitnessActivityPresets[entry.key];
      activities.add(ActivityEntry(name: name, minutes: entry.value));
      total += entry.value;
    }

    await repo.add(
      SessionEntry(
        id: repo.newId(),
        goalId: goalId,
        day: _selectedDate,
        durationMinutes: total,
        activities: activities
            .map((a) => ActivityEntry(name: a.name, minutes: a.minutes))
            .toList(growable: false),
        createdAt: DateTime.now(),
      ),
    );

    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded,
            size: 18, color: AppColors.emerald),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
              'Sesión registrada · $total min · '
              '${formatSmartDateEs(_selectedDate)}'),
        ),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SheetShell(
      title: 'Sesión fitness',
      subtitle: 'Combina actividades en un solo registro',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetDateField(
            label: '📅 ${formatSmartDateEs(_selectedDate)}',
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < kFitnessActivityPresets.length; i++)
                GestureDetector(
                  onTap: () => _toggle(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _selected.containsKey(i)
                          ? AppColors.cyan.withValues(alpha: 0.14)
                          : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _selected.containsKey(i)
                            ? AppColors.cyan
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selected.containsKey(i)) ...[
                          GestureDetector(
                            onTap: () => _adjust(i, -5),
                            child: const Icon(Icons.remove_rounded,
                                size: 15, color: AppColors.textSecondary),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${_selected[i]}′',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cyan)),
                          ),
                          GestureDetector(
                            onTap: () => _adjust(i, 5),
                            child: const Icon(Icons.add_rounded,
                                size: 15, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(kFitnessActivityPresets[i],
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selected.containsKey(i)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _selected.containsKey(i)
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: text.bodySmall?.copyWith(color: AppColors.red)),
          ],
          const SizedBox(height: 14),
          Center(
            child: Text('Total: $_total min',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text('Guardar sesión · $_total min',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

