import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/fasting_calculator.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/sheet_shell.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showFastingLogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _FastingLogSheet(),
  );
}

class _FastingLogSheet extends ConsumerStatefulWidget {
  const _FastingLogSheet();

  @override
  ConsumerState<_FastingLogSheet> createState() => _FastingLogSheetState();
}

class _FastingLogSheetState extends ConsumerState<_FastingLogSheet> {
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _endTime = const TimeOfDay(hour: 12, minute: 0);
    _startDate = now.subtract(const Duration(days: 1));
    _startTime = const TimeOfDay(hour: 20, minute: 0);
  }

  DateTime get _startDateTime => DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

  DateTime get _endDateTime => DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

  Duration get _duration => _endDateTime.difference(_startDateTime);

  Future<void> _pickDateTime({
    required bool isStart,
  }) async {
    final initialDate = isStart ? _startDate : _endDate;
    final initialTime = isStart ? _startTime : _endTime;

    final datePicked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      helpText: isStart ? 'Fecha de inicio del ayuno' : 'Fecha de fin del ayuno',
    );
    if (datePicked == null) return;

    if (!mounted) return;
    final timePicked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isStart ? 'Hora de inicio' : 'Hora de fin',
    );
    if (timePicked == null) return;

    setState(() {
      if (isStart) {
        _startDate = datePicked;
        _startTime = timePicked;
      } else {
        _endDate = datePicked;
        _endTime = timePicked;
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_duration.isNegative || _duration.inMinutes == 0) {
      setState(() => _error = 'La hora de fin debe ser posterior a la de inicio.');
      return;
    }

    final goalId = ref.read(activeGoalIdProvider);
    if (goalId.isEmpty) return;

    final repo = ref.read(sessionEntryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await repo.add(
      SessionEntry(
        id: repo.newId(),
        goalId: goalId,
        day: _endDate,
        durationMinutes: _duration.inMinutes,
        fastingStartAt: _startDateTime,
        fastingEndAt: _endDateTime,
        createdAt: DateTime.now(),
      ),
    );

    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.emerald),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
              'Ayuno guardado · ${FastingCalculator.formatDuration(_duration)}'),
        ),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SheetShell(
      title: 'Registrar ayuno',
      subtitle: 'Indica la hora de inicio y fin de tu ayuno',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hora de Inicio
          Text('Inicio del ayuno', style: text.labelMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _pickDateTime(isStart: true),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📅 ${formatSmartDateEs(_startDate)} · ${_startTime.format(context)}',
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.cyan),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Hora de Fin
          Text('Fin del ayuno', style: text.labelMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _pickDateTime(isStart: false),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📅 ${formatSmartDateEs(_endDate)} · ${_endTime.format(context)}',
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.amber),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Duración calculada
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text('Duración total del ayuno',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  _duration.isNegative
                      ? 'Error en fechas'
                      : FastingCalculator.formatDuration(_duration),
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.amber),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: text.bodySmall?.copyWith(color: AppColors.red)),
          ],

          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Guardar registro de ayuno',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
