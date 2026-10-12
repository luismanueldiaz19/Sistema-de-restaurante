import 'package:flutter/material.dart';

import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/item_comanda_temp.dart';
import '../models/mesa_model.dart';

class MesaTicketPanel extends StatelessWidget {
  final MesaModel mesa;
  final List<ItemComandaTemp> nuevosItems;
  final TextEditingController clienteController;
  final TextEditingController notaController;
  final Function(int index, double delta) onCambiarCantidad;

  const MesaTicketPanel({
    super.key,
    required this.mesa,
    required this.nuevosItems,
    required this.clienteController,
    required this.notaController,
    required this.onCambiarCantidad,
  });

  @override
  Widget build(BuildContext context) {
    final subtotalYaServido = mesa.ordenActiva?.total ?? 0.0;
    final subtotalNuevos = nuevosItems.fold(
      0.0,
      (sum, it) => sum + it.subtotal,
    );

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera Comanda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  size: 15,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Comanda de la Mesa',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (mesa.isLibre) ...[
                  SizedBox(
                    width: 140,
                    height: 28,
                    child: TextField(
                      controller: clienteController,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: 'Cliente (opcional)',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista de Artículos
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                // 1. Platos ya pedidos en cocina
                if (mesa.ordenActiva != null &&
                    mesa.ordenActiva!.detalles.isNotEmpty) ...[
                  _buildSeccionHeader(
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                    title: 'Consumo Actual (En Cocina)',
                    subtotal: subtotalYaServido,
                    titleColor: Colors.grey.shade700,
                  ),
                  const SizedBox(height: 4),
                  ...mesa.ordenActiva!.detalles.map((det) {
                    final cantStr =
                        det.cantidad % 1 == 0
                            ? det.cantidad.toInt().toString()
                            : det.cantidad.toStringAsFixed(2);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            '${cantStr}x',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              det.nombreProducto,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            FormatterNumber.formatCurrency(det.subtotal),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 14),
                ],

                // 2. Nuevos platos agregados para esta ronda
                _buildSeccionHeader(
                  icon: Icons.add_shopping_cart,
                  iconColor: AppColors.primary,
                  title: 'Ronda / Nuevos Ítems',
                  subtotal: subtotalNuevos,
                  titleColor: AppColors.primary,
                  showSubtotal: nuevosItems.isNotEmpty,
                ),
                const SizedBox(height: 6),

                if (nuevosItems.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'Toca platos o bebidas a la izquierda para agregar',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  ...nuevosItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final it = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.nombre,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  FormatterNumber.formatCurrency(it.precio),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove, size: 13),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            onPressed: () => onCambiarCantidad(i, -1),
                          ),
                          Text(
                            it.cantidad.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 13),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            onPressed: () => onCambiarCantidad(i, 1),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            FormatterNumber.formatCurrency(it.subtotal),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Instrucciones o nota de cocina
                  const SizedBox(height: 6),
                  TextField(
                    controller: notaController,
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      hintText:
                          'Instrucciones para cocina (ej. sin sal, salsa aparte)...',
                      hintStyle: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: Colors.amber.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.amber.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.amber.shade200),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required double subtotal,
    required Color titleColor,
    bool showSubtotal = true,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const Spacer(),
        if (showSubtotal)
          Text(
            FormatterNumber.formatCurrency(subtotal),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
      ],
    );
  }
}
