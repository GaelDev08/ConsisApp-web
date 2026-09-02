import 'package:consis_app/core/constants/friction_presets.dart';
import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/sheet_shell.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bitácora de fricciones ("¿Por qué no cumplí hoy?"):
/// etiquetas predefinidas + motivo personalizado + nota libre.
Future<void> showFrictionLogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: const _FrictionLogSheet(),
    ),
  );
}

class _FrictionLogSheet extends ConsumerStatefulWidget {
  const _FrictionLogSheet();

  @override
  ConsumerState<_FrictionLogSheet> createState() => _FrictionLogSheetState();
}

class _FrictionLogSheetState extends ConsumerState<_FrictionLogSheet> {
  int? _selectedPresetIndex;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _customController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _error;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'Fecha del motivo',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _hasValidReason =>
      _selectedPresetIndex != null ||
      _customController.text.trim().isNotEmpty;

  void _togglePreset(int index) {
    setState(() {
      _selectedPresetIndex =
          _selectedPresetIndex == index ? null : index;
      if (_hasValidReason) _error = null;
    });
  }

  void _onCustomChanged(String _) {
    if (_hasValidReason && _error != null) {
      setState(() => _error = null);
    }
  }

  Future<void> _save() async {
    if (!_hasValidReason) {
      setState(() => _error = 'Elige una etiqueta o escribe tu motivo');
      return;
    }

    final goalId = ref.read(activeGoalIdProvider);
    if (goalId.isEmpty) return;

    final repo = ref.read(frictionLogRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final custom = _customController.text.trim();
    final note = _noteController.text.trim();
    final day = _selectedDate;

    await repo.add(
      goalId: goalId,
      day: day,
      tag: _selectedPresetIndex != null
          ? kFrictionPresets[_selectedPresetIndex!]
          : null,
      customLabel: custom.isEmpty ? null : custom,
      note: note.isEmpty ? null : note,
    );

    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.cyan),
        const SizedBox(width: 10),
        Expanded(child: Text('Motivo registrado · ${formatSmartDateEs(day)}')),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SheetShell(
      title: '¿Qué te detuvo hoy?',
      subtitle: 'Tus motivos alimentan el resumen mensual de patrones.',
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
              for (var i = 0; i < kFrictionPresets.length; i++)
                _TagChip(
                  label: kFrictionPresets[i],
                  selected: _selectedPresetIndex == i,
                  onTap: () => _togglePreset(i),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: text.bodySmall?.copyWith(color: AppColors.red)),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _customController,
            onChanged: _onCustomChanged,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Otro motivo…',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLength: 200,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Nota (opcional): ¿qué pasó exactamente?',
              counterText: '',
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Guardar motivo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
              ? AppColors.coral.withValues(alpha: 0.14)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.coral.withValues(alpha: 0.7)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}


