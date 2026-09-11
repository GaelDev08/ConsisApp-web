import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/datetime_x.dart';
import 'package:consis_app/core/utils/screenshot_share.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/nutrition_level.dart';
import 'package:consis_app/domain/entities/weight_record.dart';
import 'package:consis_app/presentation/features/analytics/monthly_data.dart';
import 'package:consis_app/presentation/features/analytics/widgets/friction_ranking.dart';
import 'package:consis_app/presentation/providers/analytics_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

/// Fase 4 · Vista de consistencia MENSUAL.
///
/// Mapa de calor: cada día se pinta según su semáforo nutricional y
/// micro-indicadores de entrenamiento / fricción / pesaje.
class MonthlyScreen extends ConsumerStatefulWidget {
  const MonthlyScreen({super.key});

  @override
  ConsumerState<MonthlyScreen> createState() => _MonthlyScreenState();
}

class _MonthlyScreenState extends ConsumerState<MonthlyScreen> {
  late DateTime _focused = _firstOfMonth(DateTime.now());
  DateTime? _selectedDay;
  MonthlyData? _lastData;
  final GlobalKey _monthlyShareKey = GlobalKey();

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

  String get _headerTitle {
    final m = kMonthNamesEs[_focused.month - 1];
    return '${m[0].toUpperCase()}${m.substring(1)} ${_focused.year}';
  }

  bool _isToday(DateTime d) => DateTime.now().isSameDayAs(d);

  bool _isSelected(DateTime d) =>
      _selectedDay != null && _selectedDay!.isSameDayAs(d);

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(monthlyDataProvider(_firstOfMonth(_focused)));
    _lastData = data;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_headerTitle),
        actions: [
          IconButton(
            tooltip: 'Compartir progreso',
            icon: const Icon(Icons.share_rounded, color: AppColors.cyan),
            onPressed: () => ScreenshotShare.captureAndShare(
              repaintKey: _monthlyShareKey,
              context: context,
              text: '¡Mi reporte de consistencia mensual en ConsisApp! 📊🔥 #ConsisApp',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: RepaintBoundary(
            key: _monthlyShareKey,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                _calendarCard(),
                const SizedBox(height: 16),
                if (data != null) ...[
                  _summaryRow(data),
                  const SizedBox(height: 22),
                  Text('Fricciones del mes',
                      style:
                          text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  FrictionRanking(ranking: data.frictionRanking),
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.violet),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _calendarCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: TableCalendar<DateTime>(
        firstDay: DateTime(2024),
        lastDay: DateTime(2100),
        focusedDay: _focused,
        selectedDayPredicate: (day) => _isSelected(day),
        onDaySelected: (selected, focused) => setState(() {
          _selectedDay = selected;
          _focused = focused;
        }),
        onPageChanged: (focused) => setState(() => _focused = focused),
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableGestures: AvailableGestures.horizontalSwipe,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon:
              Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
          rightChevronIcon:
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          cellMargin: EdgeInsets.all(3),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) => Center(
            child: Text(
              kWeekdayStripEs[day.weekday - 1],
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          headerTitleBuilder: (context, day) => Text(
            _headerTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          defaultBuilder: (context, day, _) => _cell(day),
        ),
      ),
    );
  }

  /// Celda del mapa de calor. Con solo `defaultBuilder` provisto,
  /// table_calendar enruta HOY/SELECCIONADO también por aquí.
  Widget _cell(DateTime day) {
    final d = day.dateOnly;
    final data = _lastData;
    final isSelected = _isSelected(d);
    final isToday = _isToday(d);

    final level = data?.nutritionByDay[d];
    final worked = data?.sessionDays.contains(d) ?? false;
    final friction = data?.frictionDays.contains(d) ?? false;
    final weighed = data?.weighInDays.contains(d) ?? false;

    Color? levelColor;
    if (level != null) {
      switch (level) {
        case NutritionLevel.green:
          levelColor = AppColors.emerald;
        case NutritionLevel.yellow:
          levelColor = AppColors.amber;
        case NutritionLevel.red:
          levelColor = AppColors.red;
      }
    }

    final borderColor = isSelected
        ? AppColors.violet
        : isToday
            ? AppColors.cyan.withValues(alpha: 0.8)
            : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: levelColor?.withValues(alpha: 0.13) ??
            AppColors.surfaceHigh.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2 : (isToday ? 1.4 : 0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          SizedBox(
            height: 7,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (worked) const _MicroDot(color: AppColors.violet),
                if (levelColor != null) _MicroDot(color: levelColor),
                if (friction) const _MicroDot(color: AppColors.coral),
                if (weighed) const _MicroDot(color: AppColors.cyan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(MonthlyData data) {
    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            icon: Icons.timer_outlined,
            value: '${data.totalMinutes}',
            label: 'min en el mes',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            icon: Icons.local_fire_department_rounded,
            value: '${data.sessionDays.length}',
            label: 'días activos',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            icon: Icons.eco_rounded,
            value: '${data.nutritionConsistencyPercent}%',
            label: 'consistencia',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            icon: Icons.monitor_weight_outlined,
            value: '${data.weighInDays.length}',
            label: 'pesajes',
          ),
        ),
      ],
    );
  }
}



class _MicroDot extends StatelessWidget {
  final Color color;

  const _MicroDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 15, color: AppColors.violet.withValues(alpha: 0.9)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          Text(label,
              style: const TextStyle(
                  fontSize: 9.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}



