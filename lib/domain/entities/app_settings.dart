import 'package:flutter/material.dart' show ThemeMode;

/// Ajustes globales de la app.
///
/// - [activeGoalId]: meta EN FOCO del dashboard (selector/carrusel).
///   Cadena vacía = sin meta activa todavía.
/// - [weighInWeekday]: día oficial de pesaje usando `DateTime.weekday`
///   (1 = lunes … 7 = domingo; por defecto lunes).
///
/// La configuración de cada meta vive en la entidad [Goal] (multi-meta);
/// aquí solo queda el estado global transversal.
class AppSettings {
  /// Id fijo: la caja de ajustes contiene exactamente este registro.
  static const String singletonId = 'app_settings_singleton';

  /// Días válidos para el pesaje oficial (1..7, DateTime.weekday).
  static const int minWeekday = 1;
  static const int maxWeekday = 7;

  final String id;
  final String activeGoalId;
  final int weighInWeekday;

  /// Preferencia de tema: system, light, dark
  final ThemeMode themeMode;

  const AppSettings({
    this.id = singletonId,
    this.activeGoalId = '',
    this.weighInWeekday = DateTime.monday,
    this.themeMode = ThemeMode.system,
  }) : assert(
          weighInWeekday >= minWeekday && weighInWeekday <= maxWeekday,
          'weighInWeekday debe estar entre 1 (lunes) y 7 (domingo)',
        );

  bool get hasActiveGoal => activeGoalId.trim().isNotEmpty;

  AppSettings copyWith({
    String? id,
    String? activeGoalId,
    int? weighInWeekday,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      id: id ?? this.id,
      activeGoalId: activeGoalId ?? this.activeGoalId,
      weighInWeekday: weighInWeekday ?? this.weighInWeekday,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettings &&
          other.id == id &&
          other.activeGoalId == activeGoalId &&
          other.weighInWeekday == weighInWeekday &&
          other.themeMode == themeMode);

  @override
  int get hashCode => Object.hash(id, activeGoalId, weighInWeekday, themeMode);

  @override
  String toString() =>
      'AppSettings($id, activeGoal="$activeGoalId", weekday=$weighInWeekday, '
      'theme=${themeMode.name})';
}

