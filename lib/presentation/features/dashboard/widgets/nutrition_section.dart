import 'dart:async';

import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/nutrition_check.dart';
import 'package:consis_app/domain/entities/nutrition_level.dart';
import 'package:consis_app/presentation/features/dashboard/dashboard_data.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/section_card.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Semáforo nutricional del dashboard: check-in de 1 tap + selector de fecha.
class NutritionSection extends ConsumerStatefulWidget {
  final DashboardData data;

  const NutritionSection({super.key, required this.data});

  @override
  ConsumerState<NutritionSection> createState() => _NutritionSectionState();
}

class _NutritionSectionState extends ConsumerState<NutritionSection> {
  DateTime _selectedDay = DateTime.now();

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day;
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.violet,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDay = picked);
    }
  }

  void _setLevel(NutritionLevel level) {
    final repo = ref.read(nutritionCheckRepositoryProvider);
    unawaited(
      repo.setForDay(
        NutritionCheck(
          id: const Uuid().v4(),
          day: _selectedDay,
          level: level,
        ),
      ),
    );
  }

  NutritionLevel? get _selectedDayLevel {
    // For today, use the live dashboardData value
    if (_isToday) return widget.data.todayNutrition;
    // For past days we don't have live data - show nothing (will update after setForDay)
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: 'Semáforo nutricional',
      subtitle: _isToday ? '¿Cómo comiste hoy?' : '¿Cómo comiste ese día?',
      child: Column(
        children: [
          // Date selector row
          GestureDetector(
            onTap: _pickDay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _isToday
                        ? 'Hoy'
                        : '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down_rounded,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final level in NutritionLevel.values)
                _LevelButton(
                  level: level,
                  selected: _selectedDayLevel == level,
                  onTap: () => _setLevel(level),
                ),
            ],
          ),
          const SizedBox(height: 16),
          WeekStrip(weekNutrition: widget.data.weekNutrition),
        ],
      ),
    );
  }
}


class _LevelButton extends StatelessWidget {
  final NutritionLevel level;
  final bool selected;
  final VoidCallback onTap;

  const _LevelButton({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  Color get _color {
    switch (level) {
      case NutritionLevel.green:
        return AppColors.emerald;
      case NutritionLevel.yellow:
        return AppColors.amber;
      case NutritionLevel.red:
        return AppColors.red;
    }
  }

  String get _emoji {
    switch (level) {
      case NutritionLevel.green:
        return '🟢';
      case NutritionLevel.yellow:
        return '🟡';
      case NutritionLevel.red:
        return '🔴';
    }
  }

  String get _label {
    switch (level) {
      case NutritionLevel.green:
        return 'Bien';
      case NutritionLevel.yellow:
        return 'Extra';
      case NutritionLevel.red:
        return 'Fuera';
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 86,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: selected ? 0.16 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _color.withValues(alpha: selected ? 1 : 0.30),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 5),
            Text(
              _label,
              style: text.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// L M X J V S D con el color registrado de cada día; hoy resaltado.
class WeekStrip extends StatelessWidget {
  final List<NutritionLevel?> weekNutrition;

  const WeekStrip({super.key, required this.weekNutrition});

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday - 1;
    final text = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: weekNutrition[i] == null
                      ? Colors.transparent
                      : _colorOf(weekNutrition[i]!),
                  border: weekNutrition[i] == null
                      ? Border.all(color: AppColors.border)
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                kWeekdayStripEs[i],
                style: text.labelSmall?.copyWith(
                  color: i == todayIndex
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontWeight:
                      i == todayIndex ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Color _colorOf(NutritionLevel level) {
    switch (level) {
      case NutritionLevel.green:
        return AppColors.emerald;
      case NutritionLevel.yellow:
        return AppColors.amber;
      case NutritionLevel.red:
        return AppColors.red;
    }
  }
}
