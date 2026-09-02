import 'package:hive_ce/hive.dart';

import '../../../core/utils/datetime_x.dart';
import '../../../domain/entities/friction_log.dart';
import '../local/hive_registry.dart';

/// Modelo persistible de [FrictionLog]
/// (bitácora de motivos POR META).
class FrictionLogModel extends HiveObject {
  final String id;
  final String goalId;
  final DateTime day;
  final String? tag;
  final String? customLabel;
  final String? note;
  final DateTime createdAt;

  FrictionLogModel({
    required this.id,
    required this.goalId,
    required this.day,
    required this.createdAt,
    this.tag,
    this.customLabel,
    this.note,
  });

  factory FrictionLogModel.fromEntity(FrictionLog e) => FrictionLogModel(
        id: e.id,
        goalId: e.goalId,
        day: e.day.dateOnly,
        tag: e.tag,
        customLabel: e.customLabel,
        note: e.note,
        createdAt: e.createdAt,
      );

  FrictionLog toEntity() => FrictionLog(
        id: id,
        goalId: goalId,
        day: day.dateOnly,
        tag: tag,
        customLabel: customLabel,
        note: note,
        createdAt: createdAt,
      );

  @override
  String toString() =>
      'FrictionLogModel($id, goal=$goalId, $day, ${tag ?? customLabel ?? '-'})';
}

/// TypeAdapter manual (sin build_runner).
class FrictionLogModelAdapter extends TypeAdapter<FrictionLogModel> {
  @override
  final int typeId = BoxTypeIds.frictionLog;

  @override
  FrictionLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FrictionLogModel(
      id: fields[0] as String,
      goalId: fields[1] as String,
      day: fields[2] as DateTime,
      tag: fields[3] as String?,
      customLabel: fields[4] as String?,
      note: fields[5] as String?,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FrictionLogModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.goalId)
      ..writeByte(2)
      ..write(obj.day)
      ..writeByte(3)
      ..write(obj.tag)
      ..writeByte(4)
      ..write(obj.customLabel)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.createdAt);
  }
}
