import 'package:consis_app/core/utils/datetime_x.dart';
import 'package:consis_app/data/local/hive_manager.dart';
import 'package:consis_app/data/local/watch_box.dart';
import 'package:consis_app/data/models/nutrition_check_model.dart';
import 'package:consis_app/domain/entities/nutrition_check.dart';
import 'package:consis_app/domain/repositories/nutrition_check_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class HiveNutritionCheckRepository implements NutritionCheckRepository {
  static const Uuid _uuid = Uuid();

  Box<NutritionCheckModel> get _box => HiveManager.nutrition;

  @override
  Stream<List<NutritionCheck>> watchAll() =>
      watchBoxMapped(_box, (m) => m.toEntity());

  @override
  Future<NutritionCheck?> getByDay(DateTime day) async {
    final d = day.dateOnly;
    for (final m in _box.values) {
      if (m.day.dateOnly.isSameDayAs(d)) return m.toEntity();
    }
    return null;
  }

  @override
  Future<NutritionCheck> setForDay(NutritionCheck check) async {
    // El semáforo representa "el estado actual del día": un registro por
    // fecha; volver a tocar reemplaza el valor anterior.
    final existing = await getByDay(check.day);
    if (existing != null) {
      await _box.delete(existing.id);
    }

    final model = NutritionCheckModel.fromEntity(check);
    await _box.put(model.id, model);
    return check;
  }

  @override
  Future<void> deleteById(String id) => _box.delete(id);

  // Permite generar ids frescos sin exponer el paquete uuid a la UI.
  String newId() => _uuid.v4();
}
