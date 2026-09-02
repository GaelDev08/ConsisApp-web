import 'package:consis_app/data/local/hive_manager.dart';
import 'package:consis_app/domain/entities/user_profile.dart';
import 'package:consis_app/domain/repositories/user_profile_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/user_profile_model.dart';

class HiveUserProfileRepository implements UserProfileRepository {
  Box<UserProfileModel> get _box => HiveManager.profile;

  UserProfile readModel() =>
      _box.get(UserProfile.singletonId)?.toEntity() ?? const UserProfile();

  @override
  Stream<UserProfile> watch() async* {
    yield readModel();
    await for (final _ in _box.watch()) {
      yield readModel();
    }
  }

  @override
  Future<UserProfile> load() async => readModel();

  @override
  Future<void> save(UserProfile profile) =>
      _box.put(profile.id, UserProfileModel.fromEntity(profile));
}