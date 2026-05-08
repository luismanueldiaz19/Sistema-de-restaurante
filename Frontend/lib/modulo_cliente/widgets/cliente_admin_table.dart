import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../models/cliente.dart';

class ClienteAdminTable extends ConsumerWidget {
  final List<Cliente> clientes;
  final Function(Cliente) onEdit;
  final Function(Cliente) onDelete;

  const ClienteAdminTable({
    super.key,
    required this.clientes,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 800,
            headingRowColor: WidgetStateProperty.all(
              AppColors.azulOscuro.withValues(alpha: 0.05),
            ),
            headingRowHeight: 52,
            dataRowHeight: 60,
            columns: [
              const DataColumn2(
                label: Text(
                  "ID",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                size: ColumnSize.S,
              ),
              const DataColumn2(
                label: Text(
                  "NOMBRE COMPLETO",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                size: ColumnSize.L,
              ),
              const DataColumn2(
                label: Text(
                  "TELÉFONO",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                size: ColumnSize.M,
              ),
              const DataColumn2(
                label: Text(
                  "RNC / CÉDULA",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                size: ColumnSize.M,
              ),
              const DataColumn2(
                label: Text(
                  "DIRECCIÓN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                size: ColumnSize.L,
              ),
              const DataColumn2(
                label: Text(
                  "EMAIL",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                size: ColumnSize.M,
              ),
              if (auth.permissions.contains("editar_clientes"))
                const DataColumn2(
                  label: Text(
                    "ACCIONES",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  size: ColumnSize.S,
                  fixedWidth: 100,
                ),
            ],
            rows: clientes.asMap().entries.map((entry) {
              final index = entry.key;
              final c = entry.value;
              return DataRow2(
                onTap: () => onEdit(c),
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppColors.azulOscuro.withValues(alpha: 0.02);
                  }
                  return index.isEven ? Colors.white : Colors.grey.shade50;
                }),
                cells: [
                  DataCell(
                    Text(
                      '#${c.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      c.nombre ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(Text(c.telefono ?? '--')),
                  DataCell(Text(c.documento ?? '--')),
                  DataCell(
                    Text(c.direccion ?? '--', overflow: TextOverflow.ellipsis),
                  ),
                  DataCell(Text(c.email ?? '--')),
                  if (auth.permissions.contains("editar_clientes"))
                    DataCell(
                      Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.edit_outlined,
                            color: Colors.blue,
                            onPressed: () => onEdit(c),
                            tooltip: 'Editar',
                          ),
                          if (auth.permissions.contains("eliminar_clientes"))
                            _buildActionButton(
                              icon: Icons.delete_outline,
                              color: Colors.redAccent,
                              onPressed: () => onDelete(c),
                              tooltip: 'Eliminar',
                            ),
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(icon, color: color, size: 20),
          onPressed: onPressed,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
