import 'package:flutter/material.dart';
import 'gestion_documentos_screen.dart';

/// Pantalla unificada de Historial de Ventas y Gestión de Documentos.
///
/// Ambas pantallas han sido unificadas bajo el patrón Master-Detail
/// (Lista de facturas a la izquierda con filtros compactos y paginación,
/// y panel de detalle completo a la derecha con KPIs, tabs de artículos,
/// acciones rápidas de impresión/NC/ND y totales acumulados del período).
///
/// Esta clase redirige de forma transparente y sin duplicidad de código
/// hacia [GestionDocumentosScreen].
class HistorialVentasScreen extends StatelessWidget {
  const HistorialVentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GestionDocumentosScreen();
  }
}
