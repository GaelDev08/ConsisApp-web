import 'package:consis_app/data/repositories/hive_app_settings_repository.dart';
import 'package:consis_app/data/repositories/hive_friction_log_repository.dart';
import 'package:consis_app/data/repositories/hive_goal_repository.dart';
import 'package:consis_app/data/repositories/hive_nutrition_check_repository.dart';
import 'package:consis_app/data/repositories/hive_session_entry_repository.dart';
import 'package:consis_app/data/repositories/hive_user_profile_repository.dart';
import 'package:consis_app/data/repositories/hive_weight_record_repository.dart';
import 'package:consis_app/data/repositories/supabase_goal_repository.dart';
import 'package:consis_app/data/repositories/sync_goal_repository.dart';
import 'package:consis_app/data/repositories/supabase_repositories.dart';
import 'package:consis_app/data/repositories/sync_repositories.dart';
import 'package:consis_app/domain/repositories/app_settings_repository.dart';
import 'package:consis_app/domain/repositories/friction_log_repository.dart';
import 'package:consis_app/domain/repositories/goal_repository.dart';
import 'package:consis_app/domain/repositories/nutrition_check_repository.dart';
import 'package:consis_app/domain/repositories/session_entry_repository.dart';
import 'package:consis_app/domain/repositories/user_profile_repository.dart';
import 'package:consis_app/domain/repositories/weight_record_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return SyncGoalRepository(
    local: HiveGoalRepository(),
    remote: SupabaseGoalRepository(),
    ref: ref,
  );
});

final sessionEntryRepositoryProvider = Provider<SessionEntryRepository>((ref) {
  return SyncSessionEntryRepository(
    local: HiveSessionEntryRepository(),
    remote: SupabaseSessionEntryRepository(),
    ref: ref,
  );
});

final weightRecordRepositoryProvider = Provider<WeightRecordRepository>((ref) {
  return HiveWeightRecordRepository();
});

final frictionLogRepositoryProvider = Provider<FrictionLogRepository>((ref) {
  return HiveFrictionLogRepository();
});

final nutritionCheckRepositoryProvider = Provider<NutritionCheckRepository>((ref) {
  return HiveNutritionCheckRepository();
});

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return SyncAppSettingsRepository(
    local: HiveAppSettingsRepository(),
    remote: SupabaseAppSettingsRepository(),
    ref: ref,
  );
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return SyncUserProfileRepository(
    local: HiveUserProfileRepository(),
    remote: SupabaseUserProfileRepository(),
    ref: ref,
  );
});
