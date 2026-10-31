import 'package:flutter/material.dart';

class AppColors {
  // --- Colores Base (Style Guide) ---
  static const Color primary = Color(0xFFFF8A00);
  static const Color primaryDark = Color(0xFFE66E00);
  static const Color secondary = Color(0xFF1F2D3D);
  static const Color secondaryDark = Color(0xFF0D1117);

  // --- Estados ---
  static const Color success = Color(0xFF28C76F);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFEA5455);
  static const Color info = Color(0xFF00CFE8);

  // --- Fondos y Texto ---
  static const Color light = Color(0xFFF5F7FA);
  static const Color dark = Color(0xFF0D1117);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Legacy compatibility (remapping for existing code)
  static const Color azulOscuro = secondary;
  static const Color azulMedio = primary;
  static const Color azulClaro = Color(0xFFFFB347); // Sutil hover para el naranja
  static const Color blanco = white;
  static const Color grisClaro = light;
  static const Color error = danger;

  // --- Gradientes ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A00), Color(0xFFFF4900)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F2D3D), Color(0xFF0D1117)],
  );

  // --- Sombras ---
  static const BoxShadow sombraSuave = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  );
}
