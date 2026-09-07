import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:consis_app/domain/entities/app_settings.dart';

import '../models/app_settings_model.dart';
import '../models/friction_log_model.dart';
import '../models/goal_model.dart';
import '../models/nutrition_check_model.dart';
import '../models/session_entry_model.dart';
import '../models/user_profile_model.dart';
import '../models/weight_record_model.dart';
import 'hive_registry.dart';

/// Bootstrap de Hive para Web + Mobile.
///
/// - Web: `Hive.initFlutter()` usa **IndexedDB** automáticamente
///   (vía hive_ce_flutter), sin path_provider.
/// - Móvil/Desktop: resuelve el directorio de datos de la app.
abstract final class HiveManager {
  static bool _ready = false;

  /// Idempotente: registra adapters y abre todas las cajas tipadas,
  /// SIEMPRE cifradas con AES-256 ([HiveAesCipher]) usando la clave
  /// persistida en almacenamiento seguro.
  static Future<void> ensureInitialized({required List<int> aesKey}) async {
    if (_ready) return;

    await Hive.initFlutter();
    _registerAdapters();

    final cipher = HiveAesCipher(aesKey);

    // Abrir cada box individualmente con recuperación automática.
    // Si un box tiene datos corruptos (typeId desconocido), se borra y se recrea.
    await _openBoxSafe<GoalModel>(BoxNames.goals, cipher);
    await _openBoxSafe<SessionEntryModel>(BoxNames.sessions, cipher);
    await _openBoxSafe<WeightRecordModel>(BoxNames.weights, cipher);
    await _openBoxSafe<FrictionLogModel>(BoxNames.frictions, cipher);
    await _openBoxSafe<NutritionCheckModel>(BoxNames.nutrition, cipher);
    await _openBoxSafe<AppSettingsModel>(BoxNames.settings, cipher);
    await _openBoxSafe<UserProfileModel>(BoxNames.profile, cipher);

    // Semilla de ajustes por defecto (día de pesaje = lunes, meta 200 min).
    final settings = Hive.box<AppSettingsModel>(BoxNames.settings);
    if (settings.isEmpty) {
      await settings.put(
        AppSettings.singletonId,
        AppSettingsModel.defaults(),
      );
    }

    _ready = true;
  }

  /// Abre un box de forma segura: si falla por datos corruptos o typeId
  /// desconocido, borra el box del disco y lo recrea limpio.
  static Future<void> _openBoxSafe<T>(
    String name,
    HiveAesCipher cipher,
  ) async {
    try {
      await Hive.openBox<T>(name, encryptionCipher: cipher);
    } catch (e) {
      // Datos corruptos o typeId desconocido: borrar y recrear.
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {
        // Ignorar error al borrar.
      }
      await Hive.openBox<T>(name, encryptionCipher: cipher);
    }
  }

  static void _registerAdapters() {
    void safe<T>(int typeId, TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(typeId)) {
        Hive.registerAdapter(adapter);
      }
    }

    safe(BoxTypeIds.sessionEntry, SessionEntryModelAdapter());
    safe(BoxTypeIds.weightRecord, WeightRecordModelAdapter());
    safe(BoxTypeIds.frictionLog, FrictionLogModelAdapter());
    safe(BoxTypeIds.nutritionCheck, NutritionCheckModelAdapter());
    safe(BoxTypeIds.appSettings, AppSettingsModelAdapter());
    safe(BoxTypeIds.goal, GoalModelAdapter());
    safe(BoxTypeIds.activityEntry, ActivityEntryModelAdapter());
    safe(BoxTypeIds.userProfile, UserProfileModelAdapter());
  }

  // ---- Accesos tipados a las cajas (usados por los repos en Fases 2-4) ----

  static Box<GoalModel> get goals => Hive.box<GoalModel>(BoxNames.goals);

  static Box<SessionEntryModel> get sessions =>
      Hive.box<SessionEntryModel>(BoxNames.sessions);

  static Box<WeightRecordModel> get weights =>
      Hive.box<WeightRecordModel>(BoxNames.weights);

  static Box<FrictionLogModel> get frictions =>
      Hive.box<FrictionLogModel>(BoxNames.frictions);

  static Box<NutritionCheckModel> get nutrition =>
      Hive.box<NutritionCheckModel>(BoxNames.nutrition);

  static Box<AppSettingsModel> get settings =>
      Hive.box<AppSettingsModel>(BoxNames.settings);

  static Box<UserProfileModel> get profile =>
      Hive.box<UserProfileModel>(BoxNames.profile);
}
