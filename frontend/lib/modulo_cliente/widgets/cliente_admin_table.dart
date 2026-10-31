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
              Colors.grey.shade50,
            ),
            headingRowHeight: 45,
            dataRowHeight: 48,
            dividerThickness: 0.5,
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.5),
              verticalInside: BorderSide(color: Colors.grey.shade100, width: 0.5),
            ),
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
                fixedWidth: 60,
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
              if (auth.roles.contains('admin')) ...[
                const DataColumn2(
                  label: Text(
                    "TIPO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  size: ColumnSize.S,
                ),
                const DataColumn2(
                  label: Text(
                    "LÍMITE",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  size: ColumnSize.S,
                  numeric: true,
                ),
                const DataColumn2(
                  label: Text(
                    "ESTADO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  size: ColumnSize.S,
                  fixedWidth: 100,
                ),
              ],
              if (!auth.roles.contains('admin'))
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
              final isAdmin = auth.roles.contains('admin');

              return DataRow2(
                onTap: () => onEdit(c),
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppColors.primary.withValues(alpha: 0.04);
                  }
                  return index.isEven ? Colors.white : Colors.grey.shade50;
                }),
                cells: [
                  // ID con estilo pill
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${c.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  // Nombre con Avatar
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            c.nombre?.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.nombre ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.azulOscuro,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Icon(
                          Icons.phone_iphone,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.telefono ?? '--',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      c.rncCedula ?? '--',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.blueGrey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  if (isAdmin) ...[
                    // Tipo con badge de color
                    DataCell(_buildTypeBadge(c.tipoCliente)),
                    // Límite con estilo moneda
                    DataCell(
                      Text(
                        'RD\$ ${c.limiteCredito?.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Estado con Badge activo/inactivo
                    DataCell(_buildStatusBadge(c.activo ?? true)),
                  ],

                  if (!isAdmin)
                    DataCell(
                      Text(
                        c.direccion ?? '--',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  if (auth.permissions.contains("editar_clientes"))
                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionButton(
                            icon: Icons.edit_rounded,
                            color: Colors.indigo,
                            onPressed: () => onEdit(c),
                            tooltip: 'Editar',
                          ),
                          if (auth.permissions.contains("eliminar_clientes"))
                            _buildActionButton(
                              icon: Icons.delete_forever_rounded,
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

  Widget _buildTypeBadge(String? type) {
    Color color;
    String label;

    switch (type) {
      case 'credito':
        color = Colors.orange;
        label = 'CRÉDITO';
        break;
      case 'gubernamental':
        color = Colors.blue;
        label = 'GUBERN.';
        break;
      case 'especial':
        color = Colors.purple;
        label = 'ESPECIAL';
        break;
      default:
        color = Colors.grey;
        label = 'NORMAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 3,
            backgroundColor: active ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'ACTIVO' : 'INACTIVO',
            style: TextStyle(
              color: active ? Colors.green : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
        child: Material(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
