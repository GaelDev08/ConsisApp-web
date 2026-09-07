import 'package:hive_ce/hive.dart';

import '../../../core/utils/datetime_x.dart';
import '../../../domain/entities/activity_entry.dart';
import '../../../domain/entities/session_entry.dart';
import '../local/hive_registry.dart';

/// Sub-modelo de actividad fitness compuesta.
class ActivityEntryModel extends HiveObject {
  final String name;
  final int minutes;

  ActivityEntryModel({required this.name, required this.minutes});

  factory ActivityEntryModel.fromEntity(ActivityEntry e) =>
      ActivityEntryModel(name: e.name, minutes: e.minutes);

  ActivityEntry toEntity() => ActivityEntry(name: name, minutes: minutes);

  @override
  String toString() => '$name ${minutes}min';
}

class ActivityEntryModelAdapter extends TypeAdapter<ActivityEntryModel> {
  @override
  final int typeId = BoxTypeIds.activityEntry;

  @override
  ActivityEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityEntryModel(
      name: fields[0] as String,
      minutes: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityEntryModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..writeInt(obj.minutes);
  }
}

/// Modelo persistible unificado de [SessionEntry]
/// (estudio · fitness compuesto · ayuno · metas custom).
class SessionEntryModel extends HiveObject {
  final String id;
  final String goalId;
  final DateTime day;
  final int durationMinutes;
  final double? quantity;
  final List<ActivityEntryModel> activities;
  final List<String> tags;
  final DateTime? fastingStartAt;
  final DateTime? fastingEndAt;
  final String? note;
  final DateTime createdAt;

  SessionEntryModel({
    required this.id,
    required this.goalId,
    required this.day,
    required this.durationMinutes,
    required this.activities,
    required this.tags,
    required this.createdAt,
    this.quantity,
    this.fastingStartAt,
    this.fastingEndAt,
    this.note,
  });

  factory SessionEntryModel.fromEntity(SessionEntry e) => SessionEntryModel(
        id: e.id,
        goalId: e.goalId,
        day: e.day.dateOnly,
        durationMinutes: e.durationMinutes,
        quantity: e.quantity,
        activities:
            e.activities.map(ActivityEntryModel.fromEntity).toList(growable: false),
        tags: List<String>.unmodifiable(e.tags),
        fastingStartAt: e.fastingStartAt,
        fastingEndAt: e.fastingEndAt,
        note: e.note,
        createdAt: e.createdAt,
      );

  SessionEntry toEntity() => SessionEntry(
        id: id,
        goalId: goalId,
        day: day.dateOnly,
        durationMinutes: durationMinutes,
        quantity: quantity,
        activities:
            activities.map((m) => m.toEntity()).toList(growable: false),
        tags: tags,
        fastingStartAt: fastingStartAt,
        fastingEndAt: fastingEndAt,
        note: note,
        createdAt: createdAt,
      );

  @override
  String toString() => 'SessionEntryModel($id, goal=$goalId, $day)';
}

/// TypeAdapter manual (sin build_runner).
class SessionEntryModelAdapter extends TypeAdapter<SessionEntryModel> {
  @override
  final int typeId = BoxTypeIds.sessionEntry;

  @override
  SessionEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionEntryModel(
      id: fields[0] as String,
      goalId: fields[1] as String? ?? '',
      day: fields[2] as DateTime? ?? DateTime.now(),
      durationMinutes: (fields[3] as int?) ?? 0,
      quantity: (fields[4] as num?)?.toDouble(),
      activities: (fields[5] as List?)?.cast<ActivityEntryModel>() ?? const [],
      tags: (fields[6] as List?)?.cast<String>() ?? const [],
      fastingStartAt: fields[7] as DateTime?,
      fastingEndAt: fields[8] as DateTime?,
      note: fields[9] as String?,
      createdAt: fields[10] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, SessionEntryModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.goalId)
      ..writeByte(2)
      ..write(obj.day)
      ..writeByte(3)
      ..writeInt(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.activities)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.fastingStartAt)
      ..writeByte(8)
      ..write(obj.fastingEndAt)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.createdAt);
  }
}
