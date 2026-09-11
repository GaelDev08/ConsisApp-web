import 'package:hive_ce/hive.dart';
import 'package:consis_app/data/local/hive_registry.dart';
import 'package:consis_app/domain/entities/reminder.dart';

@HiveType(typeId: BoxTypeIds.reminder)
class ReminderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String time;

  @HiveField(3)
  final bool enabled;

  @HiveField(4)
  final String frequency;

  @HiveField(5)
  final DateTime? date;

  ReminderModel({
    required this.id,
    required this.title,
    required this.time,
    required this.enabled,
    required this.frequency,
    this.date,
  });

  factory ReminderModel.fromEntity(Reminder entity) {
    return ReminderModel(
      id: entity.id,
      title: entity.title,
      time: entity.time,
      enabled: entity.enabled,
      frequency: entity.frequency,
      date: entity.date,
    );
  }

  Reminder toEntity() {
    return Reminder(
      id: id,
      title: title,
      time: time,
      enabled: enabled,
      frequency: frequency,
      date: date,
    );
  }
}

/// Adapter manual para evitar requerir build_runner en tiempo de ejecución
class ReminderModelAdapter extends TypeAdapter<ReminderModel> {
  @override
  final int typeId = BoxTypeIds.reminder;

  @override
  ReminderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReminderModel(
      id: fields[0] as String,
      title: fields[1] as String,
      time: fields[2] as String,
      enabled: fields[3] as bool? ?? true,
      frequency: fields[4] as String? ?? 'daily',
      date: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ReminderModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.enabled)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
