import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/spanish_dates.dart';
import 'package:consis_app/domain/entities/weight_record.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeightHistoryScreen extends ConsumerWidget {
  const WeightHistoryScreen({super.key});

  Future<void> _editWeight(BuildContext context, WidgetRef ref, WeightRecord record) async {
    final ctrl = TextEditingController(text: record.weightKg.toStringAsFixed(1));
    
    final updated = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Editar pesaje', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (updated != null && updated != record.weightKg) {
      await ref.read(weightRecordRepositoryProvider).save(date: record.date, weightKg: updated);
    }
  }

  Future<void> _deleteWeight(BuildContext context, WidgetRef ref, WeightRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Eliminar pesaje?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(weightRecordRepositoryProvider).deleteById(record.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final repo = ref.watch(weightRecordRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Historial de Pesajes', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<WeightRecord>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return Center(
              child: Text(
                'Aún no hay registros de peso.',
                style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            );
          }

          final sorted = List<WeightRecord>.from(records)..sort((a, b) => b.date.compareTo(a.date));
          final chartData = List<WeightRecord>.from(records)..sort((a, b) => a.date.compareTo(b.date));

          final latest = sorted.first;
          final oldest = sorted.last;
          final diff = latest.weightKg - (sorted.length > 1 ? sorted[1].weightKg : oldest.weightKg);

          String progressText;
          Color progressColor;
          IconData progressIcon;

          if (diff < 0) {
            progressText = '¡Has bajado ${diff.abs().toStringAsFixed(1)} kg desde el pesaje anterior!';
            progressColor = AppColors.emerald;
            progressIcon = Icons.trending_down_rounded;
          } else if (diff > 0) {
            progressText = 'Has subido ${diff.toStringAsFixed(1)} kg desde el pesaje anterior.';
            progressColor = AppColors.amber;
            progressIcon = Icons.trending_up_rounded;
          } else {
            progressText = 'Te has mantenido en el mismo peso (${latest.weightKg.toStringAsFixed(1)} kg)';
            progressColor = AppColors.cyan;
            progressIcon = Icons.trending_flat_rounded;
          }

          double minY = chartData.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b) - 2;
          double maxY = chartData.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b) + 2;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: progressColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: progressColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(progressIcon, color: progressColor, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                progressText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: progressColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      if (chartData.length > 1) ...[
                        Text(
                          'Evolución',
                          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: LineChart(
                            LineChartData(
                              minY: minY,
                              maxY: maxY,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: chartData.asMap().entries.map((e) {
                                    return FlSpot(e.key.toDouble(), e.value.weightKg);
                                  }).toList(),
                                  isCurved: true,
                                  color: AppColors.cyan,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.cyan.withValues(alpha: 0.2),
                                  ),
                                ),
                              ],
                              titlesData: const FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      Text(
                        'Registro histórico',
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final r = sorted[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.scale_rounded, color: AppColors.cyan),
                          title: Text(
                            formatSmartDateEs(r.date),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Fuente: ${r.source}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${r.weightKg.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cyan,
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                                color: AppColors.surfaceHigh,
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _editWeight(context, ref, r);
                                  } else if (val == 'delete') {
                                    _deleteWeight(context, ref, r);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                  const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: AppColors.red))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: sorted.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}
