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
  String _minutesStr = '30';
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedTags = {};
  final TextEditingController _customTagCtrl = TextEditingController();

  @override
  void dispose() {
    _customTagCtrl.dispose();
    super.dispose();
  }

  int get _minutes => int.tryParse(_minutesStr) ?? 0;

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

  void _addCustomTag() {
    final text = _customTagCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _selectedTags.add(text);
        _customTagCtrl.clear();
      });
    }
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_minutesStr.isNotEmpty) {
          _minutesStr = _minutesStr.substring(0, _minutesStr.length - 1);
        }
      } else {
        if (_minutesStr == '0') {
          _minutesStr = key;
        } else if (_minutesStr.length < 3) { // max 999 minutes
          _minutesStr += key;
        }
      }
      if (_minutesStr.isEmpty) _minutesStr = '0';
    });
  }

  Future<void> _save() async {
    final goalId = ref.read(activeGoalIdProvider);
    if (goalId.isEmpty) return;

    if (_minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa al menos 1 minuto.')),
      );
      return;
    }

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
          
          // Categoría / Etiqueta personalizada
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categoría / Detalle',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customTagCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Escribe la categoría o tema...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: (_) => _addCustomTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _addCustomTag,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Añadir categoría',
                  ),
                ],
              ),
              if (_selectedTags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in _selectedTags)
                      _TagChip(
                        label: tag,
                        selected: true,
                        onTap: () => setState(() => _selectedTags.remove(tag)),
                      ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          
          // Display
          Center(
            child: Column(
              children: [
                Text(
                  _minutesStr,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                const Text(
                  'minutos',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Numpad
          _Numpad(onKeyPress: _onKeyPress),
          
          const SizedBox(height: 24),
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

class _Numpad extends StatelessWidget {
  final ValueChanged<String> onKeyPress;

  const _Numpad({required this.onKeyPress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 12),
        _buildRow(['', '0', 'backspace']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) {
        if (k.isEmpty) {
          return const SizedBox(width: 70, height: 60);
        }
        return _NumpadButton(
          keyString: k,
          onTap: () => onKeyPress(k),
        );
      }).toList(),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String keyString;
  final VoidCallback onTap;

  const _NumpadButton({required this.keyString, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBackspace = keyString == 'backspace';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 70,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isBackspace
            ? const Icon(Icons.backspace_rounded, color: AppColors.textSecondary)
            : Text(
                keyString,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}


