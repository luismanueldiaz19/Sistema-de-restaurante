import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VentasDiaBanner extends StatelessWidget {
  final double totalVentas;
  final int totalFacturas;

  const VentasDiaBanner({
    super.key,
    required this.totalVentas,
    required this.totalFacturas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.point_of_sale, size: 30, color: Colors.blue),
          const SizedBox(width: 12),
          const Text(
            'Ventas del Día',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            'Ventas: ${NumberFormat.currency(symbol: '\$').format(totalVentas)}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 20),
          Text(
            'Facturas: $totalFacturas',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
