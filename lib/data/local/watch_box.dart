import 'package:hive_ce_flutter/hive_flutter.dart';

/// Helper reactivo genérico para cajas Hive.
///
/// Emite un snapshot inicial de la caja y vuelve a emitir el snapshot
/// completo en cada evento (`add`/`update`/`delete`). Evita depender de
/// rxdart para combinar estado local simple.
Stream<List<R>> watchBoxMapped<M, R>(
  Box<M> box,
  R Function(M model) mapper,
) async* {
  List<R> snapshot() => box.values.map(mapper).toList(growable: false);

  yield snapshot();
  await for (final _ in box.watch()) {
    yield snapshot();
  }
}
