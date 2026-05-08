import 'package:flutter/material.dart';

import '../palletes/app_colors.dart';

class MesSelectorWidget extends StatefulWidget {
  final Function(int mesIndex, String mesNombre, Map<String, DateTime> rango)
  onMesSeleccionado;

  const MesSelectorWidget({super.key, required this.onMesSeleccionado});

  @override
  State<MesSelectorWidget> createState() => _MesSelectorWidgetState();
}

class _MesSelectorWidgetState extends State<MesSelectorWidget> {
  int mesActual = DateTime.now().month;

  final List<String> meses = [
    'Todos Años',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  Map<String, DateTime> obtenerRangoMes(int year, int mesIndex) {
    if (mesIndex == 0) {
      // 🔥 Rango de todo el año
      return {"inicio": DateTime(year, 1, 1), "fin": DateTime(year, 12, 31)};
    }
    // Inicio del mes
    DateTime inicio = DateTime(year, mesIndex, 1);

    // Fin del mes → se crea el primer día del siguiente mes y se resta 1 día
    DateTime fin = DateTime(
      year,
      mesIndex + 1,
      1,
    ).subtract(const Duration(days: 1));

    return {"inicio": inicio, "fin": fin};
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(meses.length, (index) {
          final seleccionado = mesActual == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                mesActual = index;
              });

              // Obtener rango
              final rango = obtenerRangoMes(DateTime.now().year, mesActual);

              print("Mes seleccionado: ${meses[index]}");
              print("Inicio: ${rango['inicio']}");
              print("Fin: ${rango['fin']}");

              widget.onMesSeleccionado(mesActual, meses[index], rango);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: seleccionado ? AppColors.azulOscuro : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                boxShadow: seleccionado
                    ? [BoxShadow(color: AppColors.azulOscuro, blurRadius: 6)]
                    : [],
              ),
              child: Text(
                meses[index],
                style: TextStyle(
                  color: seleccionado ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
