import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/sheet_shell.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal de registro de peso semanal: teclado numérico grande,
/// validación de rango y corrección del mismo día a nivel repositorio.
Future<void> showWeightLogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: const _WeightLogSheet(),
    ),
  );
}

class _WeightLogSheet extends ConsumerStatefulWidget {
  const _WeightLogSheet();

  @override
  ConsumerState<_WeightLogSheet> createState() => _WeightLogSheetState();
}

class _WeightLogSheetState extends ConsumerState<_WeightLogSheet> {
  static const double _minKg = 25;
  static const double _maxKg = 350;

  final TextEditingController _controller = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _error;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'Fecha del pesaje',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Parsea tolerando coma decimal; null si inválido o fuera de rango.
  double? get _parsedValue {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value < _minKg || value > _maxKg) return null;
    return double.parse(value.toStringAsFixed(1));
  }

  void _onChanged(String _) {
    final text = _controller.text.trim();
    String? error;
    if (text.isNotEmpty && _parsedValue == null) {
      error = 'Ingresa un peso válido entre 25 y 350 kg';
    }
    if (error != _error) {
      setState(() => _error = error);
    }
  }

  Future<void> _save() async {
    final value = _parsedValue;
    if (value == null) {
      setState(() => _error = 'Ingresa un peso válido entre 25 y 350 kg');
      return;
    }

    final repo = ref.read(weightRecordRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await repo.save(date: _selectedDate, weightKg: value);

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 18, color: AppColors.emerald),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  'Peso registrado · ${value.toStringAsFixed(1)} kg · '
                  '${formatSmartDateEs(_selectedDate)}'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
    final officialDay = kWeekdayNamesEs[(settings?.weighInWeekday ?? 1) - 1];

    return SheetShell(
      title: 'Registro de peso',
      subtitle:
          'Tu día oficial es el ${officialDay[0].toUpperCase()}${officialDay.substring(1)}',
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
            onChanged: _onChanged,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
            decoration: InputDecoration(
              hintText: '78.4',
              errorText: _error,
              counterText: '',
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 1.0,
                  child: Text('kg',
                      style: text.titleMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Guardar pesaje',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
