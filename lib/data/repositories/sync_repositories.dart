import 'dart:async';
import 'package:consis_app/data/repositories/supabase_repositories.dart';
import 'package:consis_app/presentation/providers/security_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/domain/repositories/session_entry_repository.dart';
import 'package:consis_app/domain/entities/user_profile.dart';
import 'package:consis_app/domain/repositories/user_profile_repository.dart';
import 'package:consis_app/domain/entities/app_settings.dart';
import 'package:consis_app/domain/repositories/app_settings_repository.dart';

// --- SessionEntry ---
class SyncSessionEntryRepository implements SessionEntryRepository {
  SyncSessionEntryRepository({required SessionEntryRepository local, required this.remote, required this.ref}) : _local = local;
  final SessionEntryRepository _local;
  final SupabaseSessionEntryRepository remote;
  final Ref ref;

  bool get _shouldSync => ref.read(authControllerProvider).signedInRemote;

  @override Stream<List<SessionEntry>> watchAll() => _local.watchAll();
  @override Stream<List<SessionEntry>> watchByGoal(String goalId) => _local.watchByGoal(goalId);
  @override Future<List<SessionEntry>> findByDay(DateTime day) => _local.findByDay(day);
  @override String newId() => _local.newId();
  
  @override Future<void> add(SessionEntry entry) => _save(entry);
  
  @override Future<void> addSimple({required String goalId, required DateTime day, required int minutes, List<String> tags = const [], String? note}) async {
    final entry = SessionEntry(
      id: _local.newId(),
      goalId: goalId,
      day: day,
      durationMinutes: minutes,
      tags: tags,
      note: note,
      createdAt: DateTime.now(),
    );
    await _save(entry);
  }
  
  @override Future<void> finishFasting({required String entryId, required DateTime endAt}) async {
    await _local.finishFasting(entryId: entryId, endAt: endAt);
    if (_shouldSync) {
      final entries = await _local.findByDay(endAt);
      final entry = entries.where((e) => e.id == entryId).firstOrNull;
      if (entry != null) {
        try { await remote.save(entry); } catch (e) { print('SUPABASE SYNC ERROR (finishFasting): $e'); }
      }
    }
  }

  Future<void> _save(SessionEntry e) async {
    await _local.add(e);
    if (_shouldSync) {
      try { await remote.save(e); } catch (err) { print('SUPABASE SYNC ERROR: $err'); }
    }
  }

  @override Future<void> deleteById(String id) async {
    await _local.deleteById(id);
    if (_shouldSync) { try { await remote.deleteById(id); } catch (_) {} }
  }
}

/*
class SyncWeightRecordRepository implements WeightRecordRepository {
  SyncWeightRecordRepository({required WeightRecordRepository local, required this.remote, required this.ref}) : _local = local;
  final WeightRecordRepository _local;
  final SupabaseWeightRecordRepository remote;
  final Ref ref;
  bool get _shouldSync => ref.read(authControllerProvider).signedInRemote;

  @override Stream<List<WeightRecord>> watchAll() => _local.watchAll();
  @override Future<List<WeightRecord>> loadAll() async {
    final localItems = await _local.loadAll();
    if (_shouldSync) { remote.loadAll().then((cloudItems) { for(var c in cloudItems) _local.save(c); }); }
    return localItems;
  }
  @override Future<void> save(WeightRecord e) async {
    await _local.save(e);
    if (_shouldSync) { try { await remote.save(e); } catch (_) {} }
  }
  @override Future<void> deleteById(String id) async {
    await _local.deleteById(id);
    if (_shouldSync) { try { await remote.deleteById(id); } catch (_) {} }
  }
}

// --- NutritionCheck ---
class SyncNutritionCheckRepository implements NutritionCheckRepository {
  SyncNutritionCheckRepository({required NutritionCheckRepository local, required this.remote, required this.ref}) : _local = local;
  final NutritionCheckRepository _local;
  final SupabaseNutritionCheckRepository remote;
  final Ref ref;
  bool get _shouldSync => ref.read(authControllerProvider).signedInRemote;

  @override Stream<List<NutritionCheck>> watchAll() => _local.watchAll();
  @override Future<List<NutritionCheck>> loadAll() async {
    final localItems = await _local.loadAll();
    if (_shouldSync) { remote.loadAll().then((cloudItems) { for(var c in cloudItems) _local.save(c); }); }
    return localItems;
  }
  @override Future<void> save(NutritionCheck e) async {
    await _local.save(e);
    if (_shouldSync) { try { await remote.save(e); } catch (_) {} }
  }
  @override Future<void> deleteById(String id) async {
    await _local.deleteById(id);
    if (_shouldSync) { try { await remote.deleteById(id); } catch (_) {} }
  }
}

// --- FrictionLog ---
class SyncFrictionLogRepository implements FrictionLogRepository {
  SyncFrictionLogRepository({required FrictionLogRepository local, required this.remote, required this.ref}) : _local = local;
  final FrictionLogRepository _local;
  final SupabaseFrictionLogRepository remote;
  final Ref ref;
  bool get _shouldSync => ref.read(authControllerProvider).signedInRemote;

  @override Stream<List<FrictionLog>> watchAll() => _local.watchAll();
  @override Future<List<FrictionLog>> loadAll() async {
    final localItems = await _local.loadAll();
    if (_shouldSync) { remote.loadAll().then((cloudItems) { for(var c in cloudItems) _local.save(c); }); }
    return localItems;
  }
  @override Future<FrictionLog> add({required String goalId, required DateTime day, String? tag, String? customLabel, String? note}) async {
    final res = await _local.add(goalId: goalId, day: day, tag: tag, customLabel: customLabel, note: note);
    if (_shouldSync) { try { await remote.save(res); } catch (_) {} }
    return res;
  }
  @override Future<void> deleteById(String id) async {
    await _local.deleteById(id);
    if (_shouldSync) { try { await remote.deleteById(id); } catch (_) {} }
  }
}

*/
// --- UserProfile ---
class SyncUserProfileRepository implements UserProfileRepository {
  SyncUserProfileRepository({required UserProfileRepository local, required this.remote, required this.ref}) : _local = local;
  final UserProfileRepository _local;
  final SupabaseUserProfileRepository remote;
  final Ref ref;
  bool get _shouldSync => ref.read(authControllerProvider).signedInRemote;

  @override Future<UserProfile> load() async {
    final localItem = await _local.load();
    if (_shouldSync) { unawaited(remote.loadAll().then((cloudItems) { if (cloudItems.isNotEmpty) _local.save(cloudItems.first); })); }
    return localItem;
  }
  @override Stream<UserProfile> watch() => _local.watch();
  @override Future<void> save(UserProfile e) async {
    await _local.save(e);
    if (_shouldSync) { try { await remote.save(e); } catch (_) {} }
  }
}

// --- AppSettings ---
class SyncAppSettingsRepository implements AppSettingsRepository {
  SyncAppSettingsRepository({required AppSettingsRepository local, required this.remote, required this.ref}) : _local = local;
  final AppSettingsRepository _local;
  final SupabaseAppSettingsRepository remote;
  final Ref ref;
  bool get _shouldSync => ref.read(authControllerProvider).signedInRemote;

  @override Future<AppSettings> load() async {
    final localItem = await _local.load();
    if (_shouldSync) { unawaited(remote.loadAll().then((cloudItems) { if (cloudItems.isNotEmpty) _local.save(cloudItems.first); })); }
    return localItem;
  }
  @override Stream<AppSettings> watch() => _local.watch();
  @override Future<void> save(AppSettings e) async {
    await _local.save(e);
    if (_shouldSync) { try { await remote.save(e); } catch (_) {} }
  }

  @override Future<void> updateWeighInWeekday(int weekday) async {
    await _local.updateWeighInWeekday(weekday);
    final localItem = await _local.load();
    if (_shouldSync) { try { await remote.save(localItem); } catch (_) {} }
  }
}
