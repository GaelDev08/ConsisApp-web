/// Nombres de las cajas Hive y sus TypeIds.
///
/// ⚠️ Los [BoxTypeIds] son parte del contrato de persistencia: una vez
/// publicada la app NO se deben renumerar ni reutilizar (corrompería los
/// datos existentes en IndexedDB/archivos locales). Agregar nuevos al final.
abstract final class BoxNames {
  /// Metas polivalentes (carrusel del dashboard).
  static const String goals = 'goals';

  /// Sesiones unificadas (estudio · fitness · ayuno · custom).
  static const String sessions = 'exercise_sessions';

  static const String weights = 'weight_records';
  static const String frictions = 'friction_log';
  static const String nutrition = 'nutrition_checks';
  static const String settings = 'app_settings';

  /// Perfil básico del usuario (saludo personalizado).
  static const String profile = 'user_profile';

  static const List<String> all = [
    goals,
    sessions,
    weights,
    frictions,
    nutrition,
    settings,
    profile,
  ];
}

abstract final class BoxTypeIds {
  static const int sessionEntry = 0; // antes ExerciseSession (mismo slot)
  static const int weightRecord = 1;
  static const int frictionLog = 2; // antes FrictionEntry (mismo slot)
  static const int nutritionCheck = 3;
  static const int appSettings = 4;
  static const int goal = 5;
  static const int activityEntry = 6;
  static const int userProfile = 7;
}
