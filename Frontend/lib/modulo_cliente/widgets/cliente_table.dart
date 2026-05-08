import 'package:flutter/material.dart';
import '../models/cliente.dart';

class ClienteTable extends StatelessWidget {
  final List<Cliente> clientes;
  final Function(Cliente) onSelect;

  const ClienteTable({
    super.key,
    required this.clientes,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('RNC')),
            DataColumn(label: Text('Teléfono')),
          ],
          rows: clientes.map((c) {
            return DataRow(
              onSelectChanged: (_) => onSelect(c),
              cells: [
                DataCell(Text(c.nombre ?? '')),
                DataCell(Text(c.documento ?? '')),
                DataCell(Text(c.telefono ?? '')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
