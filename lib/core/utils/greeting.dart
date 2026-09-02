/// Saludo dinámico según la hora local del dispositivo.
///
/// - 05:00–11:59 → "Buenos días ☀️"
/// - 12:00–18:59 → "Buenas tardes 🌤️"
/// - 19:00–04:59 → "Buenas noches 🌙"
abstract final class Greeting {
  /// Frase del periodo horario.
  static String periodLabel(int hour) {
    if (hour >= 5 && hour < 12) return 'Buenos días';
    if (hour >= 12 && hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  /// Emoji asociado al periodo.
  static String emoji(int hour) {
    if (hour >= 5 && hour < 12) return '☀️';
    if (hour >= 12 && hour < 19) return '🌤️';
    return '🌙';
  }

  /// Saludo completo para el header del dashboard.
  ///
  /// Con nombre: "Buenos días, Cesar ☀️".
  /// Sin nombre: "Bienvenido/a".
  static String forNow({DateTime? now, String? name}) {
    final d = now ?? DateTime.now();
    final clean = name?.trim();
    if (clean == null || clean.isEmpty) return 'Bienvenido/a';
    return '${periodLabel(d.hour)}, $clean ${emoji(d.hour)}';
  }
}