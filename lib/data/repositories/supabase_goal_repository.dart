import 'package:consis_app/data/remote/supabase_service.dart';
import 'package:consis_app/domain/entities/goal.dart';
import 'package:consis_app/domain/entities/goal_type.dart';
import 'package:consis_app/domain/repositories/goal_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositorio remoto de metas usando Supabase.
///
/// Sincroniza las metas del usuario autenticado con la tabla
/// `public.goals` en Supabase, permitiendo acceder desde cualquier
/// dispositivo con la misma cuenta.
class SupabaseGoalRepository implements GoalRepository {
  SupabaseGoalRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _sb => _client ?? SupabaseService.client;

  String get _userId => _sb.auth.currentSession?.user.id ?? '';

  bool get _isReady => _client != null || (SupabaseService.isConfigured && _userId.isNotEmpty);

  @override
  Stream<List<Goal>> watchAll() async* {
    if (!_isReady) {
      yield [];
      return;
    }

    // Emisión inicial desde la nube
    yield await _fetchFromCloud();

    // Polling periódico como fallback (compatible con todas las versiones).
    // La frecuencia de edición en metas personales es baja; 30s es suficiente.
    yield* Stream.periodic(const Duration(seconds: 30))
        .asyncMap((_) => _fetchFromCloud());
  }

  @override
  Future<List<Goal>> loadAll() async {
    if (!_isReady) return [];
    return _fetchFromCloud();
  }

  @override
  Future<void> save(Goal goal) async {
    if (!_isReady) return;

    final row = _toRow(goal);
    await _sb.from('goals').upsert(row);
  }

  @override
  Future<void> deleteById(String id) async {
    if (!_isReady) return;
    await _sb.from('goals').delete().eq('id', id);
  }

  // ---- Helpers ----

  Future<List<Goal>> _fetchFromCloud() async {
    final rows = await _sb
        .from('goals')
        .select()
        .eq('user_id', _userId)
        .order('sort_order');

    return (rows as List).map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> _toRow(Goal g) => {
        'id': g.id,
        'user_id': _userId,
        'type': g.type.name,
        'title': g.title,
        'frequency': g.frequency.name,
        'unit': g.unit.name,
        'target_value': g.targetValue,
        'context_tags': g.contextTags,
        'fasting': g.fasting == null
            ? null
            : {
                'fastHours': g.fasting!.fastHours,
                'windowHours': g.fasting!.windowHours,
              },
        'requires_nutrition': g.requiresNutritionTracking,
        'requires_weight': g.requiresWeightTracking,
        'archived': g.archived,
        'sort_order': g.sortOrder,
        'scheduled_time': g.scheduledTime,
      };

  Goal _fromRow(Map<String, dynamic> r) {
    final fastingJson = r['fasting'] as Map<String, dynamic>?;
    final fasting = fastingJson == null
        ? null
        : FastingConfig(
            fastHours: fastingJson['fastHours'] as int,
            windowHours: fastingJson['windowHours'] as int,
          );

    return Goal(
      id: r['id'] as String,
      type: GoalType.values.firstWhere(
        (t) => t.name == r['type'],
        orElse: () => GoalType.custom,
      ),
      title: r['title'] as String? ?? '',
      frequency: GoalFrequency.values.firstWhere(
        (f) => f.name == r['frequency'],
        orElse: () => GoalFrequency.daily,
      ),
      unit: GoalUnit.values.firstWhere(
        (u) => u.name == r['unit'],
        orElse: () => GoalUnit.minutes,
      ),
      targetValue: r['target_value'] as int? ?? 0,
      contextTags: (r['context_tags'] as List?)?.cast<String>() ?? const [],
      fasting: fasting,
      scheduledTime: r['scheduled_time'] as String?,
      requiresNutritionTracking: r['requires_nutrition'] as bool? ?? true,
      requiresWeightTracking: r['requires_weight'] as bool? ?? true,
      archived: r['archived'] as bool? ?? false,
      sortOrder: r['sort_order'] as int? ?? 0,
      createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}