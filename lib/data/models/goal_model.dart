import 'package:hive_ce/hive.dart';

import '../../../domain/entities/goal.dart';
import '../../../domain/entities/goal_type.dart';
import '../local/hive_registry.dart';

/// Modelo persistible de [Goal].
class GoalModel extends HiveObject {
  final String id;
  final int typeIndex;
  final String title;
  final int frequencyIndex;
  final int unitIndex;
  final int targetValue;
  final List<String> contextTags;
  final int? fastHours;
  final int? windowHours;
  final String? scheduledTime;
  final bool requiresNutritionTracking;
  final bool requiresWeightTracking;
  final bool archived;
  final int sortOrder;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.typeIndex,
    required this.title,
    required this.frequencyIndex,
    required this.unitIndex,
    required this.targetValue,
    required this.contextTags,
    required this.requiresNutritionTracking,
    required this.requiresWeightTracking,
    required this.archived,
    required this.sortOrder,
    required this.createdAt,
    this.fastHours,
    this.windowHours,
    this.scheduledTime,
  });

  factory GoalModel.fromEntity(Goal e) => GoalModel(
        id: e.id,
        typeIndex: e.type.index,
        title: e.title,
        frequencyIndex: e.frequency.index,
        unitIndex: e.unit.index,
        targetValue: e.targetValue,
        contextTags: List<String>.unmodifiable(e.contextTags),
        fastHours: e.fasting?.fastHours,
        windowHours: e.fasting?.windowHours,
        scheduledTime: e.scheduledTime,
        requiresNutritionTracking: e.requiresNutritionTracking,
        requiresWeightTracking: e.requiresWeightTracking,
        archived: e.archived,
        sortOrder: e.sortOrder,
        createdAt: e.createdAt,
      );

  Goal toEntity() {
    final fasting = (fastHours != null && windowHours != null)
        ? FastingConfig(fastHours: fastHours!, windowHours: windowHours!)
        : null;

    return Goal(
      id: id,
      type: GoalType.values[typeIndex.clamp(0, GoalType.values.length - 1)],
      title: title.trim().isEmpty ? 'Meta' : title.trim(),
      frequency: GoalFrequency.values[
          frequencyIndex.clamp(0, GoalFrequency.values.length - 1)],
      unit: GoalUnit.values[unitIndex.clamp(0, GoalUnit.values.length - 1)],
      targetValue: targetValue <= 0 ? 1 : targetValue,
      contextTags: contextTags,
      fasting: fasting,
      scheduledTime: scheduledTime,
      requiresNutritionTracking: requiresNutritionTracking,
      requiresWeightTracking: requiresWeightTracking,
      archived: archived,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'GoalModel($id, "$title")';
}

/// TypeAdapter manual (sin build_runner).
class GoalModelAdapter extends TypeAdapter<GoalModel> {
  @override
  final int typeId = BoxTypeIds.goal;

  @override
  GoalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalModel(
      id: fields[0] as String,
      typeIndex: fields[1] as int,
      title: fields[2] as String,
      frequencyIndex: fields[3] as int,
      unitIndex: fields[4] as int,
      targetValue: (fields[5] as int?) ?? 1,
      contextTags: (fields[6] as List?)?.cast<String>() ?? const [],
      fastHours: fields[7] as int?,
      windowHours: fields[8] as int?,
      scheduledTime: fields[14] as String?,
      requiresNutritionTracking: (fields[12] as bool?) ?? true,
      requiresWeightTracking: (fields[13] as bool?) ?? true,
      archived: fields[9] as bool? ?? false,
      sortOrder: (fields[10] as int?) ?? 0,
      createdAt: fields[11] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, GoalModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..writeInt(obj.typeIndex)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..writeInt(obj.frequencyIndex)
      ..writeByte(4)
      ..writeInt(obj.unitIndex)
      ..writeByte(5)
      ..writeInt(obj.targetValue)
      ..writeByte(6)
      ..write(obj.contextTags)
      ..writeByte(7)
      ..write(obj.fastHours)
      ..writeByte(8)
      ..write(obj.windowHours)
      ..writeByte(9)
      ..writeBool(obj.archived)
      ..writeByte(10)
      ..writeInt(obj.sortOrder)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..writeBool(obj.requiresNutritionTracking)
      ..writeByte(13)
      ..writeBool(obj.requiresWeightTracking)
      ..writeByte(14)
      ..write(obj.scheduledTime);
  }
}
