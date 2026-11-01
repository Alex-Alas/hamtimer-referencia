import 'package:flutter/material.dart';

/// Paleta de Hamtimer (tokens del diseño en Stitch). Solo se declaran los
/// colores que la app usa; el resto sale del `ColorScheme` de Material 3.
abstract final class AppColors {
  // Superficie base del estilo neomórfico: todo "sale" o "se hunde" de aquí.
  static const Color surface = Color(0xFFE8EAF0);
  static const Color onSurface = Color(0xFF2E3040);
  static const Color onSurfaceVariant = Color(0xFF585A68);

  static const Color primary = Color(0xFF6366F1);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF818CF8);
  static const Color primaryFixed = Color(0xFFE0E2FF);
  static const Color onPrimaryFixed = Color(0xFF1E1B4B);

  static const Color secondary = Color(0xFF6C6E7E);
  static const Color tertiary = Color(0xFF7C3AED);
  static const Color reward = Color(0xFFF59E0B);
  static const Color like = Color(0xFFE11D48);

  static const Color outline = Color(0xFF8A8C9A);
  static const Color outlineVariant = Color(0xFFD0D2DC);

  static const Color error = Color(0xFFDC2626);

  // Luz y sombra de las superficies neomórficas.
  static const Color shadowDark = Color(0x14000000);
  static const Color shadowLight = Color(0xB3FFFFFF);
}
