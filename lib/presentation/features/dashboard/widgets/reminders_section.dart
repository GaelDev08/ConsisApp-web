import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/domain/entities/reminder.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';

class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key});

  Future<void> _addReminder(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    String selectedFreq = 'daily';
    DateTime? selectedDate;

    final result = await showDialog<Reminder>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Nuevo recordatorio',
                style: TextStyle(color: AppColors.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Tomar agua, Meditar...',
                      labelText: 'Título',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Frecuencia
                  DropdownButtonFormField<String>(
                    value: selectedFreq,
                    dropdownColor: AppColors.surfaceHigh,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Todos los días')),
                      DropdownMenuItem(value: 'weekly', child: Text('Una vez por semana')),
                      DropdownMenuItem(value: 'once', child: Text('Solo una vez (Fecha)')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() {
                          selectedFreq = v;
                          if (v == 'once' && selectedDate == null) {
                            selectedDate = DateTime.now();
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fecha (solo si es "once" o "weekly" para empezar)
                  if (selectedFreq == 'once' || selectedFreq == 'weekly') ...[
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Día',
                                style: TextStyle(color: AppColors.textSecondary)),
                            Text(
                              selectedDate != null 
                                  ? formatSmartDateEs(selectedDate!) 
                                  : 'Seleccionar',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.violet,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Hora
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Hora de aviso',
                              style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            selectedTime.format(context),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.violet,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;

                  final repo = ref.read(reminderRepositoryProvider);
                  final timeStr =
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                  
                  final r = Reminder(
                    id: repo.newId(),
                    title: title,
                    time: timeStr,
                    enabled: true,
                    frequency: selectedFreq,
                    date: selectedDate,
                  );
                  Navigator.pop(ctx, r);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      await ref.read(reminderRepositoryProvider).save(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersStreamProvider);
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: AppColors.violet, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recordatorios',
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.violet),
                onPressed: () => _addReminder(context, ref),
                tooltip: 'Añadir recordatorio',
              ),
            ],
          ),
          remindersAsync.when(
            data: (reminders) {
              if (reminders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No tienes recordatorios creados.',
                    style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                );
              }

              return Column(
                children: [
                  for (final r in reminders) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        Icons.alarm_rounded,
                        color: r.enabled ? AppColors.violet : AppColors.textMuted,
                      ),
                      title: Text(
                        r.title,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration:
                              r.enabled ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(
                        r.frequency == 'daily'
                            ? 'Todos los días a las ${r.time}'
                            : r.frequency == 'weekly'
                                ? 'Semanal (${r.date != null ? _getWeekday(r.date!) : "Día"}) a las ${r.time}'
                                : 'El ${r.date != null ? formatSmartDateEs(r.date!) : "Día"} a las ${r.time}',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: r.enabled,
                            activeColor: AppColors.violet,
                            onChanged: (v) {
                              ref
                                  .read(reminderRepositoryProvider)
                                  .save(r.copyWith(enabled: v));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              ref
                                  .read(reminderRepositoryProvider)
                                  .delete(r.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.violet),
            ),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  String _getWeekday(DateTime date) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[date.weekday - 1];
  }
}
