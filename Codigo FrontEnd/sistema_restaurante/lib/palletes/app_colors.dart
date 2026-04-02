import 'package:flutter/material.dart';

class AppColors {
  // Colores base de identidad LWADER SOFT
  static const Color azulOscuro = Color(0xFF0A2A66); // Microchip y texto LWADER
  static const Color azulMedio = Color(0xFF1976D2); // Texto SOFT
  static const Color azulClaro = Color(
    0xFF64B5F6,
  ); // Hover, botones secundarios
  static const Color blanco = Color(0xFFFFFFFF); // Fondos, texto principal
  static const Color grisClaro = Color(
    0xFFF5F5F5,
  ); // Fondo de tarjetas, formularios
  static const Color grisMedio = Color(0xFFBDBDBD); // Bordes, separadores
  static const Color grisOscuro = Color(0xFF424242); // Texto secundario

  // Estados y acciones
  static const Color exito = Color(0xFF4CAF50); // Verde éxito
  static const Color error = Color(0xFFF44336); // Rojo error
  static const Color advertencia = Color(0xFFFFC107); // Amarillo advertencia
  static const Color info = Color(0xFF0288D1); // Azul informativo

  // Gradientes sugeridos
  static const LinearGradient fondoGradient = LinearGradient(
    colors: [azulOscuro, azulMedio],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sombras suaves para tarjetas
  static const BoxShadow sombraSuave = BoxShadow(
    color: Color(0x330A2A66),
    blurRadius: 8,
    offset: Offset(0, 4),
  );
}
