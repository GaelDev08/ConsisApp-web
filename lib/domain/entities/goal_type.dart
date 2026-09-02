/// Tipos, frecuencias y unidades del sistema de metas polivalente.
library;

/// Naturaleza de la meta. Determina el formulario de registro y la analítica.
enum GoalType {
  /// 🧠 Programación, lectura… minutos acumulados + etiquetas de contexto.
  timeAccumulated,

  /// 🏃 Ejercicio: sesiones compuestas multiactividad (200 min/semana).
  fitness,

  /// ⏳ Ayuno intermitente con temporizador real (16/8, 18/6…).
  fasting,

  /// ✨ Metas libres: unidad y valor definidos por el usuario.
  custom,
}

/// Cadencia del objetivo.
enum GoalFrequency { daily, weekly }

/// Unidad de medida del objetivo.
enum GoalUnit { minutes, pages, hours, sessions }

/// Configuración exclusiva de metas de ayuno intermitente.
class FastingConfig {
  final int fastHours; // horas de ayuno (16)
  final int windowHours; // ventana de comida (8)

  const FastingConfig({required this.fastHours, required this.windowHours});

  FastingConfig copyWith({int? fastHours, int? windowHours}) => FastingConfig(
        fastHours: fastHours ?? this.fastHours,
        windowHours: windowHours ?? this.windowHours,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FastingConfig &&
          other.fastHours == fastHours &&
          other.windowHours == windowHours);

  @override
  int get hashCode => Object.hash(fastHours, windowHours);

  @override
  String toString() => '$fastHours/$windowHours';
}
