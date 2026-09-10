import 'package:consis_app/data/remote/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:consis_app/domain/entities/session_entry.dart';
import 'package:consis_app/domain/entities/activity_entry.dart';
import 'package:consis_app/domain/entities/weight_record.dart';
import 'package:consis_app/domain/entities/nutrition_check.dart';
import 'package:consis_app/domain/entities/nutrition_level.dart';
import 'package:consis_app/domain/entities/friction_log.dart';
import 'package:consis_app/domain/entities/user_profile.dart';
import 'package:consis_app/domain/entities/app_settings.dart';
import 'package:flutter/material.dart' show ThemeMode;

// --- SessionEntry ---
class SupabaseSessionEntryRepository {
  SupabaseSessionEntryRepository({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;
  SupabaseClient get _sb => _client ?? SupabaseService.client;
  String get _userId => _sb.auth.currentSession?.user.id ?? '';
  bool get _isReady => _client != null || (SupabaseService.isConfigured && _userId.isNotEmpty);

  Future<List<SessionEntry>> loadAll() async {
    if (!_isReady) return [];
    final rows = await _sb.from('sessions').select().eq('user_id', _userId);
    return (rows as List).map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }
  Future<void> save(SessionEntry e) async {
    if (!_isReady) return;
    await _sb.from('sessions').upsert(_toRow(e));
  }
  Future<void> deleteById(String id) async {
    if (!_isReady) return;
    await _sb.from('sessions').delete().eq('id', id);
  }
  Map<String, dynamic> _toRow(SessionEntry e) => {
    'id': e.id, 'user_id': _userId, 'goal_id': e.goalId,
    'day': e.day.toIso8601String().split('T').first, 'duration_minutes': e.durationMinutes,
    'quantity': e.quantity, 'activities': e.activities.map((a) => {'name': a.name, 'minutes': a.minutes}).toList(),
    'tags': e.tags, 'fasting_start_at': e.fastingStartAt?.toIso8601String(),
    'fasting_end_at': e.fastingEndAt?.toIso8601String(), 'note': e.note, 'created_at': e.createdAt.toIso8601String(),
  };
  SessionEntry _fromRow(Map<String, dynamic> r) => SessionEntry(
    id: r['id'] as String, goalId: r['goal_id'] as String, day: DateTime.parse(r['day'] as String),
    durationMinutes: r['duration_minutes'] as int? ?? 0, quantity: (r['quantity'] as num?)?.toDouble(),
    activities: (r['activities'] as List?)?.map((a) => ActivityEntry(name: a['name'] as String, minutes: a['minutes'] as int)).toList() ?? [],
    tags: (r['tags'] as List?)?.cast<String>() ?? [], fastingStartAt: r['fasting_start_at'] != null ? DateTime.parse(r['fasting_start_at']) : null,
    fastingEndAt: r['fasting_end_at'] != null ? DateTime.parse(r['fasting_end_at']) : null, note: r['note'] as String?, createdAt: DateTime.parse(r['created_at'] as String),
  );
}

// --- WeightRecord ---
class SupabaseWeightRecordRepository {
  SupabaseWeightRecordRepository({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;
  SupabaseClient get _sb => _client ?? SupabaseService.client;
  String get _userId => _sb.auth.currentSession?.user.id ?? '';
  bool get _isReady => _client != null || (SupabaseService.isConfigured && _userId.isNotEmpty);

  Future<List<WeightRecord>> loadAll() async {
    if (!_isReady) return [];
    final rows = await _sb.from('weights').select().eq('user_id', _userId);
    return (rows as List).map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }
  Future<void> save(WeightRecord e) async {
    if (!_isReady) return;
    await _sb.from('weights').upsert(_toRow(e));
  }
  Future<void> deleteById(String id) async {
    if (!_isReady) return;
    await _sb.from('weights').delete().eq('id', id);
  }
  Map<String, dynamic> _toRow(WeightRecord e) => {
    'id': e.id, 'user_id': _userId, 'date': e.date.toIso8601String().split('T').first,
    'weight_kg': e.weightKg, 'source': e.source,
  };
  WeightRecord _fromRow(Map<String, dynamic> r) => WeightRecord(
    id: r['id'] as String, date: DateTime.parse(r['date'] as String),
    weightKg: (r['weight_kg'] as num).toDouble(), source: r['source'] as String,
  );
}

// --- NutritionCheck ---
class SupabaseNutritionCheckRepository {
  SupabaseNutritionCheckRepository({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;
  SupabaseClient get _sb => _client ?? SupabaseService.client;
  String get _userId => _sb.auth.currentSession?.user.id ?? '';
  bool get _isReady => _client != null || (SupabaseService.isConfigured && _userId.isNotEmpty);

  Future<List<NutritionCheck>> loadAll() async {
    if (!_isReady) return [];
    final rows = await _sb.from('nutrition_checks').select().eq('user_id', _userId);
    return (rows as List).map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }
  Future<void> save(NutritionCheck e) async {
    if (!_isReady) return;
    await _sb.from('nutrition_checks').upsert(_toRow(e));
  }
  Future<void> deleteById(String id) async {
    if (!_isReady) return;
    await _sb.from('nutrition_checks').delete().eq('id', id);
  }
  Map<String, dynamic> _toRow(NutritionCheck e) => {
    'id': e.id, 'user_id': _userId, 'day': e.day.toIso8601String().split('T').first,
    'level': e.level.index, 'note': e.note,
  };
  NutritionCheck _fromRow(Map<String, dynamic> r) => NutritionCheck(
    id: r['id'] as String, day: DateTime.parse(r['day'] as String),
    level: NutritionLevel.values[r['level'] as int], note: r['note'] as String?,
  );
}

// --- FrictionLog ---
class SupabaseFrictionLogRepository {
  SupabaseFrictionLogRepository({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;
  SupabaseClient get _sb => _client ?? SupabaseService.client;
  String get _userId => _sb.auth.currentSession?.user.id ?? '';
  bool get _isReady => _client != null || (SupabaseService.isConfigured && _userId.isNotEmpty);

  Future<List<FrictionLog>> loadAll() async {
    if (!_isReady) return [];
    final rows = await _sb.from('frictions').select().eq('user_id', _userId);
    return (rows as List).map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }
  Future<void> save(FrictionLog e) async {
    if (!_isReady) return;
    await _sb.from('frictions').upsert(_toRow(e));
  }
  Future<void> deleteById(String id) async {
    if (!_isReady) return;
    await _sb.from('frictions').delete().eq('id', id);
  }
  Map<String, dynamic> _toRow(FrictionLog e) => {
    'id': e.id, 'user_id': _userId, 'goal_id': e.goalId, 'day': e.day.toIso8601String().split('T').first,
    'tag': e.tag, 'custom_label': e.customLabel, 'note': e.note, 'created_at': e.createdAt.toIso8601String(),
  };
  FrictionLog _fromRow(Map<String, dynamic> r) => FrictionLog(
    id: r['id'] as String, goalId: r['goal_id'] as String, day: DateTime.parse(r['day'] as String),
    tag: r['tag'] as String?, customLabel: r['custom_label'] as String?, note: r['note'] as String?, createdAt: DateTime.parse(r['created_at'] as String),
  );
}

// --- UserProfile ---
class SupabaseUserProfileRepository {
  SupabaseUserProfileRepository({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;
  SupabaseClient get _sb => _client ?? SupabaseService.client;
  String get _userId => _sb.auth.currentSession?.user.id ?? '';
  bool get _isReady => _client != null || (SupabaseService.isConfigured && _userId.isNotEmpty);

  Future<List<UserProfile>> loadAll() async {
    if (!_isReady) return [];
    final rows = await _sb.from('profiles').select().eq('id', _userId);
    return (rows as List).map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }
  Future<void> save(UserProfile e) async {
    if (!_isReady) return;
    await _sb.from('profiles').upsert(_toRow(e));
  }
  Map<String, dynamic> _toRow(UserProfile e) => {
    'id': _userId, 'name': e.name, 'birthdate': e.birthdate?.toIso8601String().split('T').first,
    'country': e.country, 'address': e.address,
  };
  UserProfile _fromRow(Map<String, dynamic> r) => UserProfile(
    name: r['name'] as String, birthdate: r['birthdate'] != null ? DateTime.parse(r['birthdate'] as String) : null,
    country: r['country'] as String?, address: r['address'] as String?,
  );
}

// --- AppSettings ---
class SupabaseAppSettingsRepository {
  SupabaseAppSettingsRepository({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;
  SupabaseClient get _sb => _client ?? SupabaseService.client;
  String get _userId => _sb.auth.currentSession?.user.id ?? '';
  bool get _isReady => _client != null || (SupabaseService.isConfigured && _userId.isNotEmpty);

  Future<List<AppSettings>> loadAll() async {
    if (!_isReady) return [];
    final rows = await _sb.from('app_settings').select().eq('user_id', _userId);
    return (rows as List).map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }
  Future<void> save(AppSettings e) async {
    if (!_isReady) return;
    await _sb.from('app_settings').upsert(_toRow(e));
  }
  Map<String, dynamic> _toRow(AppSettings e) => {
    'id': _userId, 'user_id': _userId, 'active_goal_id': e.activeGoalId, 'weigh_in_weekday': e.weighInWeekday,
    'theme_mode': e.themeMode.name,
  };
  AppSettings _fromRow(Map<String, dynamic> r) => AppSettings(
    activeGoalId: r['active_goal_id'] as String? ?? '', weighInWeekday: r['weigh_in_weekday'] as int? ?? 1,
    themeMode: ThemeMode.values.firstWhere((m) => m.name == r['theme_mode'], orElse: () => ThemeMode.system),
  );
}
