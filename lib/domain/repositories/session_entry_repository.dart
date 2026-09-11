import '../entities/session_entry.dart';

/// Contrato del registro unificado de sesiones
/// (estudio · fitness compuesto · ayuno · metas custom).
abstract interface class SessionEntryRepository {
  /// Todas las sesiones de todas las metas (reactivo).
  Stream<List<SessionEntry>> watchAll();

  /// Descarga/sincroniza las sesiones desde Supabase.
  Future<List<SessionEntry>> loadAll();

  /// Sesiones de UNA meta (reactivo) — desglose semanal por meta.
  Stream<List<SessionEntry>> watchByGoal(String goalId);

  Future<List<SessionEntry>> findByDay(DateTime day);

  /// Inserta/actualiza la entrada (upsert por id).
  /// El [SessionEntry.day] define la semana/mes donde se acumula.
  Future<void> add(SessionEntry entry);

  /// Registro rápido de minutos (flujo ~2 taps) sin construir entidad en UI.
  Future<void> addSimple({
    required String goalId,
    required DateTime day,
    required int minutes,
    List<String> tags = const [],
    String? note,
  });

  /// Id fresco para construir entidades desde la UI sin exponer uuid.
  String newId();

  /// Ayuno: marca el fin y persiste la duración final.
  Future<void> finishFasting({
    required String entryId,
    required DateTime endAt,
  });

  Future<void> deleteById(String id);
}
