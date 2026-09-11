import 'package:consis_app/core/utils/datetime_x.dart';
import 'package:consis_app/data/local/hive_manager.dart';
import 'package:consis_app/data/local/watch_box.dart';
import 'package:consis_app/data/models/session_entry_model.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/domain/repositories/session_entry_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class HiveSessionEntryRepository implements SessionEntryRepository {
  static const Uuid _uuid = Uuid();

  Box<SessionEntryModel> get _box => HiveManager.sessions;

  @override
  Stream<List<SessionEntry>> watchAll() =>
      watchBoxMapped(_box, (m) => m.toEntity());

  @override
  Future<List<SessionEntry>> loadAll() async {
    return _box.values.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Stream<List<SessionEntry>> watchByGoal(String goalId) async* {
    await for (final all in watchAll()) {
      yield all.where((e) => e.goalId == goalId).toList(growable: false);
    }
  }

  @override
  Future<List<SessionEntry>> findByDay(DateTime day) async {
    final d = day.dateOnly;
    return _box.values
        .where((m) => m.day.dateOnly.isSameDayAs(d))
        .map((m) => m.toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> add(SessionEntry entry) async {
    final model = SessionEntryModel.fromEntity(entry);
    await _box.put(model.id, model);
  }

  @override
  Future<void> addSimple({
    required String goalId,
    required DateTime day,
    required int minutes,
    List<String> tags = const [],
    String? note,
  }) async {
    final now = DateTime.now();
    final entity = SessionEntry(
      id: _uuid.v4(),
      goalId: goalId,
      day: day,
      durationMinutes: minutes,
      tags: tags,
      note: note,
      createdAt: now,
    );
    final model = SessionEntryModel.fromEntity(entity);
    await _box.put(model.id, model);
  }

  @override
  Future<void> finishFasting({
    required String entryId,
    required DateTime endAt,
  }) async {
    final model = _box.get(entryId);
    if (model == null || model.fastingStartAt == null) return;

    final start = model.fastingStartAt!;
    final safeEnd =
        endAt.isBefore(start) ? start : endAt; // nunca duración negativa

    final updated = SessionEntryModel(
      id: model.id,
      goalId: model.goalId,
      day: model.day,
      durationMinutes: safeEnd.difference(start).inMinutes,
      quantity: model.quantity,
      activities: model.activities,
      tags: model.tags,
      fastingStartAt: model.fastingStartAt,
      fastingEndAt: safeEnd,
      note: model.note,
      createdAt: model.createdAt,
    );
    await _box.put(updated.id, updated);
  }

  @override
  Future<void> deleteById(String id) => _box.delete(id);

  /// Id fresco para construir entidades desde la UI sin exponer uuid.
  @override
  String newId() => _uuid.v4();
}
