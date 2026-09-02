import 'package:consis_app/core/constants/goal_defaults.dart';
import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/app_settings.dart';
import 'package:consis_app/domain/entities/goal.dart';
import 'package:consis_app/domain/entities/goal_type.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/sheet_shell.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
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
              trailing: g.id == activeId
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.emerald)
                  : const Icon(Icons.radio_button_unchecked_rounded,
                      color: AppColors.textMuted),
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
        const SizedBox(height: 18),
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
      sortOrder: widget.existingCount,
      createdAt: now,
    );

    await ref.read(goalRepositoryProvider).save(goal);

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
        const Icon(Icons.check_circle_rounded,
            size: 18, color: AppColors.emerald),
        const SizedBox(width: 10),
        Expanded(child: Text('Meta "$title" creada')),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepBtn(
                  icon: Icons.remove_rounded,
                  onTap: () =>
                      setState(() => _target = (_target - 5).clamp(1, 5000))),
              Text(
                  '$_target ${goalUnitLabel(_unit)} · '
                  '${goalFrequencyLabel(_freq).toLowerCase()}',
                  style:
                      text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              _StepBtn(
                  icon: Icons.add_rounded,
                  onTap: () =>
                      setState(() => _target = (_target + 5).clamp(1, 5000))),
            ],
          ),
        ],
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





