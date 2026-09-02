import 'package:consis_app/core/constants/goal_defaults.dart';
import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/goal_type.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/sheet_shell.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal para metas CUSTOM libres: cantidad en la unidad elegida
/// (páginas leídas, horas estudiadas, sesiones completadas…).
Future<void> showQuantityLogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _QuantityLogSheet(),
  );
}

class _QuantityLogSheet extends ConsumerStatefulWidget {
  const _QuantityLogSheet();

  @override
  ConsumerState<_QuantityLogSheet> createState() => _QuantityLogSheetState();
}

class _QuantityLogSheetState extends ConsumerState<_QuantityLogSheet> {
  final TextEditingController _controller = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'Fecha del registro',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  double? get _parsed {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return null;
    return v;
  }

  Future<void> _save() async {
    final value = _parsed;
    if (value == null) {
      setState(() => _error = 'Ingresa una cantidad mayor a 0');
      return;
    }

    final goalId = ref.read(activeGoalIdProvider);
    if (goalId.isEmpty) return;

    final goal = ref.read(activeGoalProvider);
    final unitLabel =
        goal == null ? 'unidades' : goalUnitLabel(goal.unit);

    final repo = ref.read(sessionEntryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await repo.add(
      SessionEntry(
        id: repo.newId(),
        goalId: goalId,
        day: _selectedDate,
        quantity: value,
        durationMinutes: goal?.unit == GoalUnit.hours
            ? (value * 60).round()
            : 0,
        createdAt: DateTime.now(),
      ),
    );

    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.emerald),
        const SizedBox(width: 10),
        Text('Registro guardado · ${_fmt(value)} $unitLabel'),
      ]),
    ));
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    ref.listen(activeGoalProvider, (_, __) {});
    final goal = ref.watch(activeGoalProvider);
    final text = Theme.of(context).textTheme;
    final unitLabel = goal == null ? '' : goalUnitLabel(goal.unit);

    return SheetShell(
      title: 'Registrar progreso',
      subtitle: unitLabel.isEmpty ? null : 'Unidad: $unitLabel',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetDateField(
            label: '📅 ${formatSmartDateEs(_selectedDate)}',
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: text.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: '0',
              errorText: _error,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 1.0,
                  child: Text(unitLabel,
                      style: text.titleMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Guardar registro',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
