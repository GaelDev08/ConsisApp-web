import 'package:hive_ce/hive.dart';

import 'package:consis_app/domain/entities/app_settings.dart';
import '../local/hive_registry.dart';

import 'package:flutter/material.dart' show ThemeMode;

/// Modelo persistible de [AppSettings] (caja singleton).
///
/// Guarda la meta EN FOCO del carrusel ([activeGoalId]) y el **día de
/// pesaje oficial configurable** (1=lunes … 7=domingo, por defecto lunes).
class AppSettingsModel extends HiveObject {
  final String id;
  final String activeGoalId;
  final int weighInWeekday;
  final String themeMode;

  AppSettingsModel({
    required this.id,
    required this.activeGoalId,
    required this.weighInWeekday,
    required this.themeMode,
  });

  factory AppSettingsModel.defaults() {
    const d = AppSettings();
    return AppSettingsModel(
      id: d.id,
      activeGoalId: d.activeGoalId,
      weighInWeekday: d.weighInWeekday,
      themeMode: d.themeMode.name,
    );
  }

  factory AppSettingsModel.fromEntity(AppSettings e) => AppSettingsModel(
        id: e.id,
        activeGoalId: e.activeGoalId,
        weighInWeekday: e.weighInWeekday,
        themeMode: e.themeMode.name,
      );

  /// Normaliza datos leídos de disco que pudieran estar fuera de rango
  /// (defensivo ante versiones previas o ediciones manuales).
  AppSettings toEntity() {
    final weekday =
        weighInWeekday.clamp(AppSettings.minWeekday, AppSettings.maxWeekday);
    
    ThemeMode tm;
    switch (themeMode) {
      case 'light':
        tm = ThemeMode.light;
        break;
      case 'dark':
        tm = ThemeMode.dark;
        break;
      default:
        tm = ThemeMode.system;
    }

    return AppSettings(
      id: id,
      activeGoalId: activeGoalId.trim(),
      weighInWeekday: weekday,
      themeMode: tm,
    );
  }

  @override
  String toString() =>
      'AppSettingsModel($id, activeGoal="$activeGoalId", '
      'weekday=$weighInWeekday, theme=$themeMode)';
}

/// TypeAdapter manual (sin build_runner).
class AppSettingsModelAdapter extends TypeAdapter<AppSettingsModel> {
  @override
  final int typeId = BoxTypeIds.appSettings;

  @override
  AppSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettingsModel(
      id: fields[0] as String? ?? '',
      activeGoalId: fields[1] as String? ?? '',
      weighInWeekday: (fields[2] as int?) ?? 1,
      themeMode: (fields[3] as String?) ?? 'system',
    );
  }

  @override
  void write(BinaryWriter writer, AppSettingsModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.activeGoalId)
      ..writeByte(2)
      ..writeInt(obj.weighInWeekday)
      ..writeByte(3)
      ..write(obj.themeMode);
  }
}
