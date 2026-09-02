import 'package:hive_ce/hive.dart';

import 'package:consis_app/core/utils/datetime_x.dart';
import 'package:consis_app/domain/entities/weight_record.dart';
import '../local/hive_registry.dart';

/// Modelo persistible de [WeightRecord] (pesaje semanal oficial).
class WeightRecordModel extends HiveObject {
  final String id;
  final DateTime date;
  final double weightKg;
  final String source;

  WeightRecordModel({
    required this.id,
    required this.date,
    required this.weightKg,
    required this.source,
  });

  factory WeightRecordModel.fromEntity(WeightRecord e) => WeightRecordModel(
        id: e.id,
        date: e.date.dateOnly,
        weightKg: e.weightKg,
        source: e.source,
      );

  WeightRecord toEntity() => WeightRecord(
        id: id,
        date: date.dateOnly,
        weightKg: weightKg,
        source: source,
      );

  @override
  String toString() => 'WeightRecordModel($id, $date, ${weightKg}kg, $source)';
}

/// TypeAdapter manual (sin build_runner).
class WeightRecordModelAdapter extends TypeAdapter<WeightRecordModel> {
  @override
  final int typeId = BoxTypeIds.weightRecord;

  @override
  WeightRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeightRecordModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      weightKg: (fields[2] as num).toDouble(),
      source: (fields[3] as String?) ?? 'manual',
    );
  }

  @override
  void write(BinaryWriter writer, WeightRecordModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..writeDouble(obj.weightKg)
      ..writeByte(3)
      ..write(obj.source);
  }
}
