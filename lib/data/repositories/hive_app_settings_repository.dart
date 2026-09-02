import 'package:consis_app/data/local/hive_manager.dart';
import 'package:consis_app/data/models/app_settings_model.dart';
import 'package:consis_app/domain/entities/app_settings.dart';
import 'package:consis_app/domain/repositories/app_settings_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveAppSettingsRepository implements AppSettingsRepository {
  Box<AppSettingsModel> get _box => HiveManager.settings;

  AppSettings _read() =>
      _box.get(AppSettings.singletonId)?.toEntity() ?? const AppSettings();

  @override
  Stream<AppSettings> watch() async* {
    yield _read();
    await for (final _ in _box.watch()) {
      yield _read();
    }
  }

  @override
  Future<AppSettings> load() async => _read();

  @override
  Future<void> save(AppSettings settings) =>
      _box.put(AppSettings.singletonId, AppSettingsModel.fromEntity(settings));

  @override
  Future<void> updateWeighInWeekday(int weekday) async {
    final current = await load();
    final safe = weekday < AppSettings.minWeekday
        ? AppSettings.minWeekday
        : (weekday > AppSettings.maxWeekday
            ? AppSettings.maxWeekday
            : weekday);
    await save(current.copyWith(weighInWeekday: safe));
  }
}
