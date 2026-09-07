import 'dart:async';

import 'package:consis_app/data/repositories/supabase_goal_repository.dart';
import 'package:consis_app/domain/entities/goal.dart';
import 'package:consis_app/domain/repositories/goal_repository.dart';
import 'package:consis_app/presentation/providers/security_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repositorio sincronizado: Hive local + Supabase remoto.
///
/// Estrategia offline-first:
/// - Toda lectura/escritura va primero a Hive (rápido, funciona sin internet).
/// - Si hay sesión activa en Supabase, se sincroniza en segundo plano.
/// - Al arrancar con sesión, se descargan las metas de la nube y se fusionan
///   con las locales (la nube gana en conflicto por ser la "fuente de verdad"
///   compartida entre dispositivos).
class SyncGoalRepository implements GoalRepository {
  SyncGoalRepository({
    required GoalRepository local,
    required this.remote,
    required this.ref,
  }) : _local = local;

  final GoalRepository _local;
  final SupabaseGoalRepository remote;
  final Ref ref;

  bool get _shouldSync {
    final auth = ref.read(authControllerProvider);
    return auth.signedInRemote;
  }

  @override
  Stream<List<Goal>> watchAll() async* {
    // Siempre emitir desde local primero (inmediato)
    await for (final goals in _local.watchAll()) {
      yield goals;
    }
  }

  @override
  Future<List<Goal>> loadAll() async {
    final localGoals = await _local.loadAll();

    // Si hay sesión remota, sincronizar en segundo plano
    if (_shouldSync) {
      unawaited(_syncDownThenUp(localGoals));
    }

    return localGoals;
  }

  @override
  Future<void> save(Goal goal) async {
    // 1. Guardar localmente siempre (offline-first)
    await _local.save(goal);

    // 2. Sincronizar a la nube si hay sesión
    if (_shouldSync) {
      try {
        await remote.save(goal);
      } catch (_) {
        // Fallo de red: se reintentará en la próxima sincronización
      }
    }
  }

  @override
  Future<void> deleteById(String id) async {
    await _local.deleteById(id);

    if (_shouldSync) {
      try {
        await remote.deleteById(id);
      } catch (_) {
        // Fallo de red: se reintentará después
      }
    }
  }

  /// Descarga metas de la nube y las fusiona con las locales.
  /// Luego sube las locales que no están en la nube.
  Future<void> _syncDownThenUp(List<Goal> localGoals) async {
    try {
      final cloudGoals = await remote.loadAll();
      final cloudIds = cloudGoals.map((g) => g.id).toSet();

      // Fusionar: para cada meta en la nube, sobrescribir la local
      for (final cloudGoal in cloudGoals) {
        await _local.save(cloudGoal);
      }

      // Subir locales que no existen en la nube
      for (final localGoal in localGoals) {
        if (!cloudIds.contains(localGoal.id)) {
          await remote.save(localGoal);
        }
      }
    } catch (_) {
      // Sin red: se queda con lo local, se reintentará después
    }
  }
}