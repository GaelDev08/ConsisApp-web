import '../../domain/entities/goal_type.dart';

/// Presets de la arquitectura polivalente de metas.

/// Etiquetas de contexto sugeridas para metas de estudio/código.
const List<String> kStudyContextTagPresets = <String>[
  'Backend / Laravel',
  'Frontend',
  'Bases de Datos / SQL',
  'Proyectos personales',
  'Algoritmos',
  'Inglés técnico',
];

/// Actividades sugeridas para sesiones fitness compuestas.
const List<String> kFitnessActivityPresets = <String>[
  'Running',
  'Caminata',
  'HIIT',
  'Bicicleta',
  'Fuerza',
  'Estiramiento',
  'Natación',
];

/// Preset de ventana de ayuno intermitente.
class FastingPreset {
  final String label;
  final int fastHours;
  final int windowHours;

  const FastingPreset({
    required this.label,
    required this.fastHours,
    required this.windowHours,
  });
}

const List<FastingPreset> kFastingPresets = <FastingPreset>[
  FastingPreset(label: '14/10', fastHours: 14, windowHours: 10),
  FastingPreset(label: '16/8', fastHours: 16, windowHours: 8),
  FastingPreset(label: '18/6', fastHours: 18, windowHours: 6),
  FastingPreset(label: '20/4', fastHours: 20, windowHours: 4),
];

/// Etiquetas legibles para UI.
String goalUnitLabel(GoalUnit unit) {
  switch (unit) {
    case GoalUnit.minutes:
      return 'minutos';
    case GoalUnit.pages:
      return 'páginas';
    case GoalUnit.hours:
      return 'horas';
    case GoalUnit.sessions:
      return 'sesiones';
  }
}

String goalFrequencyLabel(GoalFrequency frequency) {
  switch (frequency) {
    case GoalFrequency.daily:
      return 'Diaria';
    case GoalFrequency.weekly:
      return 'Semanal';
  }
}

/// Etiqueta corta de unidad para anillos/chips compactos.
String goalUnitShort(GoalUnit unit) {
  switch (unit) {
    case GoalUnit.minutes:
      return 'min';
    case GoalUnit.pages:
      return 'págs';
    case GoalUnit.hours:
      return 'h';
    case GoalUnit.sessions:
      return 'ses';
  }
}

String goalTypeLabel(GoalType type) {
  switch (type) {
    case GoalType.timeAccumulated:
      return 'Tiempo / Habilidad';
    case GoalType.fitness:
      return 'Fitness';
    case GoalType.fasting:
      return 'Ayuno';
    case GoalType.custom:
      return 'Personalizada';
  }
}
