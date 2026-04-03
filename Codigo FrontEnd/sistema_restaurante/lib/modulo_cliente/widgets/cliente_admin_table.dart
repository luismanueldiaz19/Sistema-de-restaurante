import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../models/cliente.dart';

class ClienteAdminTable extends StatelessWidget {
  final List<Cliente> clientes;
  final Function(Cliente) onEdit;

  const ClienteAdminTable({
    super.key,
    required this.clientes,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
            headingRowHeight: 42,
            border: TableBorder.all(color: Colors.grey.shade300),
            horizontalMargin: 12,
            columns: [
              // id, nombre, telefono, direccion, documento, email,
              DataColumn(label: Text("Id")),
              DataColumn(label: Text("Nombre")),
              DataColumn(label: Text("Teléfono")),
              DataColumn(label: Text("documento")),
              DataColumn(label: Text("direccion")),

              DataColumn(label: Text("email")),
              if (auth.permissions.contains("editar_clientes"))
                DataColumn(label: Text("Acciones")),
            ],
            rows: clientes.asMap().entries.map((entry) {
              int index = entry.key;
              final c = entry.value;
              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.blue.shade50; // hover
                  }
                  return index.isEven ? Colors.white : Colors.grey.shade200;
                }),
                cells: [
                  DataCell(Text('# ${c.id}')),
                  DataCell(Text(c.nombre ?? '')),

                  DataCell(Text(c.telefono ?? '')),
                  DataCell(Text(c.documento ?? '')),
                  DataCell(Text(c.direccion ?? '')),
                  DataCell(Text(c.email ?? '')),

                  /// ✏️ ACCIONES
                  if (auth.permissions.contains("editar_clientes"))
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => onEdit(c),
                          ),
                          // IconButton(
                          //   icon: const Icon(Icons.delete, color: Colors.red),
                          //   onPressed: () {
                          //     // eliminar
                          //   },
                          // ),
                        ],
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
