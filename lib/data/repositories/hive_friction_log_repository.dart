import 'package:consis_app/core/utils/datetime_x.dart';
import 'package:consis_app/data/local/hive_manager.dart';
import 'package:consis_app/data/local/watch_box.dart';
import 'package:consis_app/data/models/friction_log_model.dart';
import 'package:consis_app/domain/entities/friction_log.dart';
import 'package:consis_app/domain/repositories/friction_log_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class HiveFrictionLogRepository implements FrictionLogRepository {
  static const Uuid _uuid = Uuid();

  Box<FrictionLogModel> get _box => HiveManager.frictions;

  @override
  Stream<List<FrictionLog>> watchAll() =>
      watchBoxMapped(_box, (m) => m.toEntity());

  @override
  Stream<List<FrictionLog>> watchByGoal(String goalId) async* {
    await for (final all in watchAll()) {
      yield all.where((f) => f.goalId == goalId).toList(growable: false);
    }
  }

  @override
  Future<List<FrictionLog>> findByDay(DateTime day) async {
    final d = day.dateOnly;
    return _box.values
        .where((m) => m.day.dateOnly.isSameDayAs(d))
        .map((m) => m.toEntity())
        .toList(growable: false);
  }

  @override
  Future<FrictionLog> add({
    required String goalId,
    required DateTime day,
    String? tag,
    String? customLabel,
    String? note,
  }) {
    assert(
      (tag != null && tag.trim().isNotEmpty) ||
          (customLabel != null && customLabel.trim().isNotEmpty),
      'Se requiere una etiqueta predefinida o un motivo personalizado',
    );

    final entity = FrictionLog(
      id: _uuid.v4(),
      goalId: goalId,
      day: day.dateOnly,
      tag: tag?.trim(),
      customLabel: customLabel?.trim(),
      note: note?.trim(),
      createdAt: DateTime.now(),
    );
    return _box
        .put(entity.id, FrictionLogModel.fromEntity(entity))
        .then((_) => entity);
  }

  @override
  Future<void> save(FrictionLog log) async {
    await _box.put(log.id, FrictionLogModel.fromEntity(log));
  }

  @override
  Future<void> deleteById(String id) => _box.delete(id);

  String newId() => _uuid.v4();
}
