import 'package:consis_app/data/repositories/hive_app_settings_repository.dart';
import 'package:consis_app/data/repositories/hive_friction_log_repository.dart';
import 'package:consis_app/data/repositories/hive_goal_repository.dart';
import 'package:consis_app/data/repositories/hive_nutrition_check_repository.dart';
import 'package:consis_app/data/repositories/hive_session_entry_repository.dart';
import 'package:consis_app/data/repositories/hive_user_profile_repository.dart';
import 'package:consis_app/data/repositories/hive_weight_record_repository.dart';
import 'package:consis_app/domain/repositories/app_settings_repository.dart';
import 'package:consis_app/domain/repositories/friction_log_repository.dart';
import 'package:consis_app/domain/repositories/goal_repository.dart';
import 'package:consis_app/domain/repositories/nutrition_check_repository.dart';
import 'package:consis_app/domain/repositories/session_entry_repository.dart';
import 'package:consis_app/domain/repositories/user_profile_repository.dart';
import 'package:consis_app/domain/repositories/weight_record_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bindings de repositorios (Data ← inyección hacia Presentation).
///
/// Cambiar la implementación aquí basta para swap completo de storage.

final goalRepositoryProvider = Provider<GoalRepository>(
  (_) => HiveGoalRepository(),
);

final sessionEntryRepositoryProvider = Provider<SessionEntryRepository>(
  (_) => HiveSessionEntryRepository(),
);

final weightRecordRepositoryProvider = Provider<WeightRecordRepository>(
  (_) => HiveWeightRecordRepository(),
);

final frictionLogRepositoryProvider = Provider<FrictionLogRepository>(
  (_) => HiveFrictionLogRepository(),
);

final nutritionCheckRepositoryProvider = Provider<NutritionCheckRepository>(
  (_) => HiveNutritionCheckRepository(),
);

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>(
  (_) => HiveAppSettingsRepository(),
);

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (_) => HiveUserProfileRepository(),
);
