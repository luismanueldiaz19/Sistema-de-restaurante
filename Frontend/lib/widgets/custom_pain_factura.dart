// =============================
// 🎨 CUSTOM PAINTER PARA EL CORTE
// =============================
import 'package:flutter/material.dart';

class FacturaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.white; // Color de la factura

    Path path = Path();

    double triangleSize = 10; // Tamaño del diente

    // 🔵 Comenzamos desde la esquina superior izquierda
    path.moveTo(0, 0);

    // 🔽 Triángulos superiores
    for (double i = 0; i < size.width; i += triangleSize * 2) {
      path.lineTo(i + triangleSize, triangleSize);
      path.lineTo(i + (triangleSize * 2), 0);
    }

    // 📏 Lado derecho
    path.lineTo(size.width, size.height);

    // 🔽 Triángulos inferiores
    for (double i = size.width; i > 0; i -= triangleSize * 2) {
      path.lineTo(i - triangleSize, size.height - triangleSize);
      path.lineTo(i - (triangleSize * 2), size.height);
    }

    // 📏 Lado izquierdo
    path.lineTo(0, 0);
    path.close();

    // 🖌️ Dibujar la forma
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
