import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

class UltimasVentasTable extends StatelessWidget {
  final List<VentaItem> ventas;

  const UltimasVentasTable({super.key, required this.ventas});

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimas Ventas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DataTable2(
              columns: const [
                DataColumn(label: Text('N° Factura')),
                DataColumn(label: Text('Cliente')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Estado')),
              ],
              rows: ventas.map((v) {
                return DataRow(
                  cells: [
                    DataCell(Text(v.factura)),
                    DataCell(Text(v.cliente)),
                    DataCell(Text('\$${v.total.toStringAsFixed(2)}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _estadoColor(v.estado),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          v.estado,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class VentaItem {
  final String factura;
  final String cliente;
  final double total;
  final String estado;

  VentaItem({
    required this.factura,
    required this.cliente,
    required this.total,
    required this.estado,
  });
}
