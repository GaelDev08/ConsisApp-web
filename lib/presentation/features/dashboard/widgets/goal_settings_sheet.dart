import 'package:consis_app/core/constants/goal_defaults.dart';
import 'package:consis_app/core/services/notification_service.dart';
import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/app_settings.dart';
import 'package:consis_app/domain/entities/goal.dart';
import 'package:consis_app/domain/entities/goal_type.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/sheet_shell.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:consis_app/presentation/security/widgets/pin_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Gestor de metas polivalentes: lista, activar en foco y crear nuevas.
///
/// El dashboard mantiene UNA meta en foco ([AppSettings.activeGoalId]);
/// aquí se administran todas sin perder el hiperenfoque visual.
Future<void> showGoalSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _GoalsSheet(),
  );
}

enum _GoalsView { list, create }

class _GoalsSheet extends ConsumerStatefulWidget {
  const _GoalsSheet();

  @override
  ConsumerState<_GoalsSheet> createState() => _GoalsSheetState();
}

class _GoalsSheetState extends ConsumerState<_GoalsSheet> {
  _GoalsView _view = _GoalsView.list;

  Future<void> _setActive(String goalId) async {
    final settings = ref.read(appSettingsStreamProvider).valueOrNull;
    if (settings == null) return;
    await ref
        .read(appSettingsRepositoryProvider)
        .save(settings.copyWith(activeGoalId: goalId));
  }

  /// Avisa cuando la meta quedó guardada localmente pero no pudo
  /// sincronizarse con la cuenta (Supabase).
  void _notifySyncFailure(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_rounded, size: 18, color: AppColors.amber),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Guardado en este dispositivo, pero no se sincronizó con tu '
            'cuenta: $error',
          ),
        ),
      ]),
    ));
  }

  Future<void> _editGoal(Goal goal) async {
    final controller = TextEditingController(text: goal.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Editar meta',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Nombre de la meta',
            hintStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.violet),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != goal.title) {
      final updated = goal.copyWith(title: result);
      try {
        await ref.read(goalRepositoryProvider).save(updated);
      } catch (e) {
        _notifySyncFailure(e);
      }

      // Si era la meta activa, mantenerla activa tras la edición
      final settings = ref.read(appSettingsStreamProvider).valueOrNull;
      if (settings?.activeGoalId == goal.id) {
        await ref
            .read(appSettingsRepositoryProvider)
            .save(settings!.copyWith(activeGoalId: goal.id));
      }
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar meta',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Seguro que quieres eliminar "${goal.title}"?\n\nEsta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(goalRepositoryProvider).deleteById(goal.id);

      // Si era la meta activa, limpiar la selección
      final settings = ref.read(appSettingsStreamProvider).valueOrNull;
      if (settings?.activeGoalId == goal.id) {
        final goals = ref.read(goalsStreamProvider).valueOrNull ?? [];
        final nextActive = goals.where((g) => g.id != goal.id && !g.archived).firstOrNull;
        await ref
            .read(appSettingsRepositoryProvider)
            .save(settings!.copyWith(activeGoalId: nextActive?.id ?? ''));
      }
    }
  }

  Future<void> _toggleArchive(Goal goal) async {
    final updated = goal.copyWith(archived: !goal.archived);
    try {
      await ref.read(goalRepositoryProvider).save(updated);
    } catch (e) {
      _notifySyncFailure(e);
    }

    // Si archivamos la meta activa, mover el foco a otra meta
    if (goal.archived == false) {
      final settings = ref.read(appSettingsStreamProvider).valueOrNull;
      if (settings?.activeGoalId == goal.id) {
        final goals = ref.read(goalsStreamProvider).valueOrNull ?? [];
        final nextActive =
            goals.where((g) => g.id != goal.id && !g.archived).firstOrNull;
        await ref
            .read(appSettingsRepositoryProvider)
            .save(settings!.copyWith(activeGoalId: nextActive?.id ?? ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsStreamProvider).valueOrNull ?? const <Goal>[];
    final activeId = ref.watch(activeGoalIdProvider);
    final weekday =
        ref.watch(appSettingsStreamProvider).valueOrNull?.weighInWeekday ?? 1;
    final text = Theme.of(context).textTheme;

    final Widget content = _view == _GoalsView.list
        ? _buildList(goals, activeId, weekday, text)
        : _CreateGoalForm(
            existingCount: goals.length,
            onBackToMenu: () => setState(() => _view = _GoalsView.list),
          );

    return SheetShell(
      title: 'Metas',
      subtitle: _view == _GoalsView.list
          ? 'Toca una meta para ponerla en foco'
          : null,
      child: content,
    );
  }

  Widget _buildList(
      List<Goal> goals, String activeId, int weekday, TextTheme text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (goals.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.violet.withValues(alpha: 0.3)),
            ),
            child: Text('Aún no hay metas · crea la primera 👇',
                style: text.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary)),
          )
        else
          for (final g in goals)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(_iconFor(g.type), color: _colorFor(g.type)),
              title: Text(g.title,
                  style: text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${goalTypeLabel(g.type)} · ${goalFrequencyLabel(g.frequency)} · '
                '${g.targetValue} ${goalUnitLabel(g.unit)}',
                style: text.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (g.id == activeId)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.emerald, size: 22)
                  else
                    Icon(Icons.radio_button_unchecked_rounded,
                        color: AppColors.textMuted.withValues(alpha: 0.5), size: 22),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) async {
                      switch (value) {
                        case 'activate':
                          await _setActive(g.id);
                          if (mounted) Navigator.of(context).pop();
                        case 'edit':
                          await _editGoal(g);
                        case 'delete':
                          await _deleteGoal(g);
                        case 'archive':
                          await _toggleArchive(g);
                        case 'unarchive':
                          await _toggleArchive(g);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_rounded, color: AppColors.violet),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'activate',
                        child: ListTile(
                          leading: Icon(Icons.center_focus_strong_rounded,
                              color: AppColors.cyan),
                          title: Text('Activar'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      if (!g.archived)
                        const PopupMenuItem(
                          value: 'archive',
                          child: ListTile(
                            leading: Icon(Icons.archive_rounded,
                                color: AppColors.textSecondary),
                            title: Text('Archivar'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'unarchive',
                          child: ListTile(
                            leading: Icon(Icons.unarchive_rounded,
                                color: AppColors.textSecondary),
                            title: Text('Desarchivar'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_rounded, color: AppColors.red),
                          title: Text('Eliminar',
                              style: TextStyle(color: AppColors.red)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert_rounded,
                        color: AppColors.textMuted, size: 20),
                  ),
                ],
              ),
              onTap: () => _setActive(g.id),
            ),
        const Divider(height: 26),
        Text('Día de pesaje oficial',
            style: text.labelMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (var i = 0; i < kWeekdayStripEs.length; i++)
              ButtonSegment(value: i + 1, label: Text(kWeekdayStripEs[i])),
          ],
          selected: {weekday},
          onSelectionChanged: (sel) async {
            final settings = ref.read(appSettingsStreamProvider).valueOrNull;
            if (settings == null) return;
            await ref
                .read(appSettingsRepositoryProvider)
                .save(settings.copyWith(weighInWeekday: sel.first));
          },
        ),

        FilledButton.icon(
          onPressed: () => setState(() => _view = _GoalsView.create),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nueva meta'),
        ),
      ],
    );
  }
}

class _CreateGoalForm extends ConsumerStatefulWidget {
  final int existingCount;
  final VoidCallback onBackToMenu;

  const _CreateGoalForm({
    required this.existingCount,
    required this.onBackToMenu,
  });

  @override
  ConsumerState<_CreateGoalForm> createState() => _CreateGoalFormState();
}

class _CreateGoalFormState extends ConsumerState<_CreateGoalForm> {
  final TextEditingController _titleCtrl = TextEditingController();
  GoalType _type = GoalType.timeAccumulated;
  GoalFrequency _freq = GoalFrequency.weekly;
  GoalUnit _unit = GoalUnit.minutes;
  int _target = 200;
  FastingPreset _fastPreset = kFastingPresets[1]; // 16/8 por defecto
  bool _customHealthTracking = true; // solo visible en metas CUSTOM
  bool _saving = false;
  TimeOfDay? _scheduledTime;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _setType(GoalType type) {
    setState(() {
      _type = type;
      // Regla de dominio: al cambiar de tipo se recalcula el tracking
      // automático (custom permite elegirlo de nuevo).
      _customHealthTracking = true;
      if (type == GoalType.fitness) {
        _freq = GoalFrequency.weekly;
        _unit = GoalUnit.minutes;
        _target = 200;
      } else if (type == GoalType.timeAccumulated &&
          _freq == GoalFrequency.daily &&
          _target > 240) {
        _target = 60;
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _pickTargetWithKeypad() async {
    String currentVal = _target.toString();
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
                    'Ingresa la meta (${goalUnitLabel(_unit)})',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentVal.isEmpty ? '0' : currentVal,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.violet,
                    ),
                  ),
                  const SizedBox(height: 16),
                  NumericKeypad(
                    onDigit: (digit) {
                      setModalState(() {
                        if (currentVal == '0') {
                          currentVal = digit;
                        } else if (currentVal.length < 5) {
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
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (result != null && result > 0) {
      setState(() => _target = result);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final now = DateTime.now();

    // Regla de dominio: solo fitness/fasting/custom (salud) arrastran
    // nutrición y peso; timeAccumulated los desactiva siempre.
    final healthTracking =
        _type == GoalType.timeAccumulated ? false : _customHealthTracking;

    final goal = Goal(
      id: const Uuid().v4(),
      type: _type,
      title: title,
      frequency: _freq,
      unit: _type == GoalType.fasting ? GoalUnit.hours : _unit,
      targetValue: _type == GoalType.fasting ? _fastPreset.fastHours : _target,
      fasting: _type == GoalType.fasting
          ? FastingConfig(
              fastHours: _fastPreset.fastHours,
              windowHours: _fastPreset.windowHours,
            )
          : null,
      requiresNutritionTracking: healthTracking,
      requiresWeightTracking: healthTracking,
      scheduledTime: _scheduledTime == null
          ? null
          : '${_scheduledTime!.hour.toString().padLeft(2, '0')}:'
              '${_scheduledTime!.minute.toString().padLeft(2, '0')}',
      sortOrder: widget.existingCount,
      createdAt: now,
    );

    Object? syncError;
    try {
      await ref.read(goalRepositoryProvider).save(goal);
    } catch (e, st) {
      // ignore: avoid_print
      debugPrint('[SyncGoal] ERROR al sincronizar meta: $e\n$st');
      syncError = e;
    }
    // Recordatorio diario (solo móvil). Si la meta no tiene horario, no se programa.
    await NotificationService.scheduleGoalReminder(
      goalId: goal.id,
      title: goal.title,
      time: goal.scheduledTime ?? '',
    );

    // Sin meta activa previa ⇒ esta queda en foco automáticamente.
    final settings = ref.read(appSettingsStreamProvider).valueOrNull;
    if (settings != null && !settings.hasActiveGoal) {
      await ref
          .read(appSettingsRepositoryProvider)
          .save(settings.copyWith(activeGoalId: goal.id));
    }

    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          syncError != null
              ? Icons.warning_rounded
              : Icons.check_circle_rounded,
          size: 18,
          color: syncError != null ? AppColors.amber : AppColors.emerald,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            syncError != null
                ? 'Meta guardada en este dispositivo, pero no se pudo '
                    'sincronizar con tu cuenta: $syncError'
                : 'Meta "$title" creada',
          ),
        ),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBackToMenu,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              color: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text('Nueva meta',
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleCtrl,
          maxLength: 30,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Título (ej. Programación, Cardio, Ayuno…)',
            counterText: '',
          ),
        ),
        const SizedBox(height: 14),
        Text('Tipo',
            style:
                text.labelMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SegmentedButton<GoalType>(
          segments: const [
            ButtonSegment(value: GoalType.timeAccumulated, label: Text('Tiempo')),
            ButtonSegment(value: GoalType.fitness, label: Text('Fitness')),
            ButtonSegment(value: GoalType.fasting, label: Text('Ayuno')),
            ButtonSegment(value: GoalType.custom, label: Text('Libre')),
          ],
          selected: {_type},
          onSelectionChanged: (sel) => _setType(sel.first),
        ),
        if (_type == GoalType.fasting) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in kFastingPresets)
                GestureDetector(
                  onTap: () => setState(() => _fastPreset = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _fastPreset == p
                          ? AppColors.amber.withValues(alpha: 0.16)
                          : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color:
                            _fastPreset == p ? AppColors.amber : AppColors.border,
                      ),
                    ),
                    child: Text(p.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _fastPreset == p
                                ? AppColors.textPrimary
                                : AppColors.textSecondary)),
                  ),
                ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 12),
          SegmentedButton<GoalFrequency>(
            segments: const [
              ButtonSegment(value: GoalFrequency.daily, label: Text('Diaria')),
              ButtonSegment(value: GoalFrequency.weekly, label: Text('Semanal')),
            ],
            selected: {_freq},
            onSelectionChanged: (sel) => setState(() => _freq = sel.first),
          ),
          if (_type == GoalType.custom) ...[
            const SizedBox(height: 10),
            SegmentedButton<GoalUnit>(
              segments: const [
                ButtonSegment(value: GoalUnit.minutes, label: Text('min')),
                ButtonSegment(value: GoalUnit.pages, label: Text('págs')),
                ButtonSegment(value: GoalUnit.hours, label: Text('horas')),
                ButtonSegment(value: GoalUnit.sessions, label: Text('sesión')),
              ],
              selected: {_unit},
              onSelectionChanged: (sel) => setState(() => _unit = sel.first),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _customHealthTracking,
              onChanged: (v) => setState(() => _customHealthTracking = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeThumbColor: AppColors.emerald,
              title: const Text('Nutrición y peso',
                  style: TextStyle(fontSize: 14)),
              subtitle: const Text('Semáforo diario + pesaje semanal',
                  style: TextStyle(fontSize: 11)),
            ),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickTargetWithKeypad,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.violet.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Objetivo (${goalFrequencyLabel(_freq).toLowerCase()})',
                        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_target ${goalUnitLabel(_unit)}',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.violet,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text('Toca para cambiar',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      SizedBox(width: 6),
                      Icon(Icons.edit_rounded, color: AppColors.violet, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                value: _scheduledTime != null,
                onChanged: (v) => setState(() =>
                    _scheduledTime = v
                        ? const TimeOfDay(hour: 8, minute: 0)
                        : null),
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_rounded,
                    color: AppColors.violet),
                title: const Text('Recordatorio diario',
                    style: TextStyle(fontSize: 14)),
                subtitle: Text(
                    _scheduledTime == null
                        ? 'Recibe una notificación para no olvidarlo'
                        : 'Todos los días a las ${_scheduledTime!.format(context)}',
                    style: const TextStyle(fontSize: 11)),
              ),
              if (_scheduledTime != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.schedule_rounded,
                      color: AppColors.cyan),
                  title: const Text('Cambiar hora',
                      style: TextStyle(fontSize: 13)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted),
                  onTap: _pickTime,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _save,
          style:
              FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Crear meta',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

IconData _iconFor(GoalType type) {
  switch (type) {
    case GoalType.timeAccumulated:
      return Icons.code_rounded;
    case GoalType.fitness:
      return Icons.fitness_center_rounded;
    case GoalType.fasting:
      return Icons.hourglass_bottom_rounded;
    case GoalType.custom:
      return Icons.star_border_rounded;
  }
}

Color _colorFor(GoalType type) {
  switch (type) {
    case GoalType.timeAccumulated:
      return AppColors.violet;
    case GoalType.fitness:
      return AppColors.cyan;
    case GoalType.fasting:
      return AppColors.amber;
    case GoalType.custom:
      return AppColors.emerald;
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}





