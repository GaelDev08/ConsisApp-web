/// Etiquetas predefinidas para la bitácora de fricciones
/// ("¿Por qué no cumplí hoy?").
///
/// Se registran tal cual en [FrictionEntry.tag] para poder agregar
/// patrones recurrentes en el resumen mensual (Fase 4). El usuario
/// también puede escribir un motivo personalizado ([FrictionEntry.customLabel]).
const List<String> kFrictionPresets = <String>[
  'Lluvia / Clima',
  'Cansancio',
  'Falta de tiempo / Trabajo',
  'Salud / Molestia',
  'Falta de motivación',
  'Dolor muscular / Recuperación',
];
