import 'package:flutter/material.dart';

/// Paleta Dark-Mode Premium de ConsisApp.
///
/// Fondo profundo, tarjetas con elevación suave y bordes sutiles,
/// más los acentos semánticos del dominio (éxito / meta / extras / fricción).
abstract final class AppColors {
  // ---- Fondos ----
  static const Color bg = Color(0xFF121218); // fondo principal
  static const Color bgDeep = Color(0xFF0F172A); // fondos alternos / gradiente
  static const Color surface = Color(0xFF1E1E2D); // tarjetas
  static const Color surfaceHigh = Color(0xFF262636); // chips / inputs / hover
  static const Color border = Color(0xFF2E2E3E); // bordes sutiles

  // ---- Texto ----
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // ---- Acentos semánticos ----
  static const Color emerald = Color(0xFF10B981); // éxito · 🟢 nutrición
  static const Color violet = Color(0xFF8B5CF6); // meta de minutos
  static const Color cyan = Color(0xFF06B6D4); // meta de minutos (gradiente)
  static const Color amber = Color(0xFFF59E0B); // extras / 🟡 flexible
  static const Color coral = Color(0xFFF87171); // días con fricción/motivo
  static const Color red = Color(0xFFEF4444); // 🔴 fuera de plan

  /// Gradiente oficial de la meta de minutos.
  static const LinearGradient goalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, cyan],
  );

  /// Color del nivel del semáforo nutricional.
  static Color nutritionColor(int levelIndex) {
    switch (levelIndex) {
      case 0:
        return emerald; // green
      case 1:
        return amber; // yellow
      case 2:
        return red; // red
      default:
        return textMuted;
    }
  }

  /// Paleta de fondos configurables (selector "Color de fondo" en Metas).
  static const List<({int value, String label})> backgroundPresets =
      <({int value, String label})>[
    (value: 0xFF121218, label: 'Negro profundo'),
    (value: 0xFF16202E, label: 'Azul petróleo'),
    (value: 0xFF1B2A22, label: 'Verde bosque'),
    (value: 0xFF2A1B2E, label: 'Púrpura oscuro'),
    (value: 0xFF2E1F16, label: 'Café'),
];
}
