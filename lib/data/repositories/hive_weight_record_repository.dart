import 'package:consis_app/core/utils/datetime_x.dart';
import 'package:consis_app/data/local/hive_manager.dart';
import 'package:consis_app/data/local/watch_box.dart';
import 'package:consis_app/data/models/weight_record_model.dart';
import 'package:consis_app/domain/entities/weight_record.dart';
import 'package:consis_app/domain/repositories/weight_record_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class HiveWeightRecordRepository implements WeightRecordRepository {
  static const Uuid _uuid = Uuid();

  Box<WeightRecordModel> get _box => HiveManager.weights;

  @override
  Stream<List<WeightRecord>> watchAll() =>
      watchBoxMapped(_box, (m) => m.toEntity());

  @override
  Future<WeightRecord?> latest() async {
    WeightRecord? best;
    for (final m in _box.values) {
      final e = m.toEntity();
      if (best == null || e.date.isAfter(best.date)) best = e;
    }
    return best;
  }

  @override
  Future<WeightRecord> save({
    required DateTime date,
    required double weightKg,
  }) async {
    final d = date.dateOnly;

    // El pesaje oficial es único por fecha: si ya existe ese día se
    // corrige en lugar de duplicar.
    String id = _uuid.v4();
    for (final m in _box.values) {
      if (m.date.dateOnly.isSameDayAs(d)) {
        id = m.id;
        break;
      }
    }

    final entity = WeightRecord(id: id, date: d, weightKg: weightKg);
    await _box.put(entity.id, WeightRecordModel.fromEntity(entity));
    return entity;
  }

  @override
  Future<int> importHistory(List<WeightRecord> records) async {
    var inserted = 0;
    for (final r in records) {
      final exists =
          _box.values.any((m) => m.date.dateOnly.isSameDayAs(r.date));
      if (exists) continue;

      final entity = WeightRecord(
        id: _uuid.v4(),
        date: r.date.dateOnly,
        weightKg: r.weightKg,
        source: r.source.isEmpty ? 'import_3m' : r.source,
      );
      await _box.put(entity.id, WeightRecordModel.fromEntity(entity));
      inserted++;
    }
    return inserted;
  }

  @override
  Future<void> deleteById(String id) => _box.delete(id);
}
