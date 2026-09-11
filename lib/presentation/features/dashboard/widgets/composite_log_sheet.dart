import 'package:consis_app/core/constants/goal_defaults.dart';
import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/activity_entry.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/sheet_shell.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:consis_app/presentation/security/widgets/pin_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal de sesión FITNESS compuesta multiactividad:
/// selecciona o añade actividades y ajusta los minutos con el teclado numérico.
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
  /// Nombre de actividad -> minutos asignados.
  final Map<String, int> _selected = {};
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _customActivityCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _customActivityCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _pickMinutesForKeypad(String activityName) async {
    String currentVal = (_selected[activityName] ?? 30).toString();
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Minutos para $activityName',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${currentVal.isEmpty ? '0' : currentVal} min',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(height: 16),
                  NumericKeypad(
                    onDigit: (digit) {
                      setModalState(() {
                        if (currentVal == '0') {
                          currentVal = digit;
                        } else if (currentVal.length < 3) {
                          currentVal += digit;
                        }
                      });
                    },
                    onDelete: () {
                      setModalState(() {
                        if (currentVal.isNotEmpty) {
                          currentVal =
                              currentVal.substring(0, currentVal.length - 1);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final parsed = int.tryParse(currentVal);
                      Navigator.pop(context, parsed ?? 0);
                    },
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                    child: const Text('Confirmar minutos'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null && result > 0) {
      setState(() {
        _selected[activityName] = result;
        _error = null;
      });
    }
  }

  void _toggleOrEdit(String activityName) {
    if (_selected.containsKey(activityName)) {
      // Si ya está seleccionada, al tocar abre el teclado numérico para cambiar minutos
      _pickMinutesForKeypad(activityName);
    } else {
      // Primera selección por defecto: abre el teclado numérico
      _selected[activityName] = 30;
      _pickMinutesForKeypad(activityName);
    }
  }

  void _removeActivity(String activityName) {
    setState(() {
      _selected.remove(activityName);
    });
  }

  void _addCustomActivity() {
    final text = _customActivityCtrl.text.trim();
    if (text.isNotEmpty) {
      _customActivityCtrl.clear();
      _selected[text] = 30;
      _pickMinutesForKeypad(text);
    }
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
      activities.add(ActivityEntry(name: entry.key, minutes: entry.value));
      total += entry.value;
    }

    await repo.add(
      SessionEntry(
        id: repo.newId(),
        goalId: goalId,
        day: _selectedDate,
        durationMinutes: total,
        activities: activities,
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

    // Presets que no están añadidos aún
    final allPresets = {...kFitnessActivityPresets, ..._selected.keys};

    return SheetShell(
      title: 'Sesión fitness',
      subtitle: 'Toca una actividad para ingresar sus minutos con el teclado',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetDateField(
            label: '📅 ${formatSmartDateEs(_selectedDate)}',
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),

          // Input para nueva actividad personalizada
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customActivityCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Añadir otra actividad (ej. Padel, Yoga...)',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _addCustomActivity(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _addCustomActivity,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Añadir actividad',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Chips de actividades
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in allPresets)
                GestureDetector(
                  onTap: () => _toggleOrEdit(name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _selected.containsKey(name)
                          ? AppColors.cyan.withValues(alpha: 0.16)
                          : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _selected.containsKey(name)
                            ? AppColors.cyan
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selected.containsKey(name)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _selected.containsKey(name)
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary)),
                        if (_selected.containsKey(name)) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_selected[name]} min',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cyan),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _removeActivity(name),
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: AppColors.textMuted),
                          ),
                        ],
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
            child: Text('Total acumulado: $_total min',
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

