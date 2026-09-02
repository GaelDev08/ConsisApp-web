import 'package:consis_app/data/local/hive_manager.dart';
import 'package:consis_app/data/local/watch_box.dart';
import 'package:consis_app/data/models/goal_model.dart';
import 'package:consis_app/domain/entities/goal.dart';
import 'package:consis_app/domain/repositories/goal_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveGoalRepository implements GoalRepository {
  Box<GoalModel> get _box => HiveManager.goals;

  static int _comparator(Goal a, Goal b) {
    final byOrder = a.sortOrder.compareTo(b.sortOrder);
    return byOrder != 0 ? byOrder : a.createdAt.compareTo(b.createdAt);
  }

  @override
  Stream<List<Goal>> watchAll() async* {
    await for (final list
        in watchBoxMapped(_box, (GoalModel m) => m.toEntity())) {
      final sorted = [...list]..sort(_comparator);
      yield sorted;
    }
  }

  @override
  Future<List<Goal>> loadAll() async {
    final list = _box.values.map((m) => m.toEntity()).toList();
    list.sort(_comparator);
    return list;
  }

  @override
  Future<void> save(Goal goal) =>
      _box.put(goal.id, GoalModel.fromEntity(goal));

  @override
  Future<void> deleteById(String id) => _box.delete(id);
}
