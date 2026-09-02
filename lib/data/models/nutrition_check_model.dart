import 'package:hive_ce/hive.dart';

import 'package:consis_app/core/utils/datetime_x.dart';
import 'package:consis_app/domain/entities/nutrition_check.dart';
import 'package:consis_app/domain/entities/nutrition_level.dart';
import '../local/hive_registry.dart';

/// Modelo persistible de [NutritionCheck] (semáforo nutricional diario).
///
/// El enum se persiste como índice (`int`) para evitar un TypeAdapter extra.
class NutritionCheckModel extends HiveObject {
  final String id;
  final DateTime day;

  /// Índice de [NutritionLevel.values].
  final int levelIndex;
  final String? note;

  NutritionCheckModel({
    required this.id,
    required this.day,
    required this.levelIndex,
    this.note,
  });

  factory NutritionCheckModel.fromEntity(NutritionCheck e) =>
      NutritionCheckModel(
        id: e.id,
        day: e.day.dateOnly,
        levelIndex: e.level.index,
        note: e.note,
      );

  NutritionLevel get level => NutritionLevel.values[levelIndex];

  NutritionCheck toEntity() => NutritionCheck(
        id: id,
        day: day.dateOnly,
        level: level,
        note: note,
      );

  @override
  String toString() => 'NutritionCheckModel($id, $day, $levelIndex)';
}

/// TypeAdapter manual (sin build_runner).
class NutritionCheckModelAdapter extends TypeAdapter<NutritionCheckModel> {
  @override
  final int typeId = BoxTypeIds.nutritionCheck;

  @override
  NutritionCheckModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionCheckModel(
      id: fields[0] as String,
      day: fields[1] as DateTime,
      levelIndex: fields[2] as int,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NutritionCheckModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.day)
      ..writeByte(2)
      ..writeInt(obj.levelIndex)
      ..writeByte(3)
      ..write(obj.note);
  }
}
