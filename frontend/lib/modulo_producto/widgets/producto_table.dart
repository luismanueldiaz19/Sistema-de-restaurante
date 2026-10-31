import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../models/producto.dart';

class ProductoTable extends ConsumerWidget {
  final List<Producto> productos;
  final Function(Producto) onEdit;
  final Function(Producto) onDelete;

  const ProductoTable({
    super.key,
    required this.productos,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isAdmin = auth.roles.contains('admin');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          minWidth: 900,
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          headingRowHeight: 45,
          dataRowHeight: 52,
          dividerThickness: 0.5,
          border: TableBorder(
            horizontalInside: BorderSide(
              color: Colors.grey.shade200,
              width: 0.5,
            ),
            verticalInside: BorderSide(color: Colors.grey.shade100, width: 0.5),
          ),
          columns: [
            const DataColumn2(
              label: Text(
                "CÓDIGO",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              size: ColumnSize.S,
              fixedWidth: 100,
            ),
            const DataColumn2(
              label: Text(
                "PRODUCTO",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              size: ColumnSize.L,
            ),
            const DataColumn2(
              label: Text("UND", style: TextStyle(fontWeight: FontWeight.bold)),
              size: ColumnSize.L,
            ),
            const DataColumn2(
              label: Text(
                "CATEGORÍA",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              size: ColumnSize.S,
              fixedWidth: 110,
            ),
            const DataColumn2(
              label: Text(
                "PRECIO",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              size: ColumnSize.S,
              numeric: true,
            ),
            const DataColumn2(
              label: Text(
                "STOCK",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              size: ColumnSize.S,
              numeric: true,
            ),
            if (isAdmin) ...[
              const DataColumn2(
                label: Text(
                  "COSTO",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.S,
                numeric: true,
              ),
              const DataColumn2(
                label: Text(
                  "ESTADO",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.S,
                fixedWidth: 100,
              ),
            ],
            if (auth.hasPermission('editar_productos'))
              const DataColumn2(
                label: Text(
                  "ACCIONES",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                size: ColumnSize.S,
                fixedWidth: 100,
              ),
          ],
          rows: productos.asMap().entries.map((entry) {
            final p = entry.value;
            final index = entry.key;

            return DataRow2(
              color: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return AppColors.primary.withValues(alpha: 0.04);
                }
                return index.isEven ? Colors.white : Colors.grey.shade50;
              }),
              cells: [
                DataCell(
                  Text(
                    p.codigo ?? '--',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ),

                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fastfood_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.nombre ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(p.unidadMedida?.nombre ?? '--')),
                DataCell(_buildCategoryBadge(p.categoria?.nombre)),
                DataCell(
                  Text(
                    'RD\$ ${p.precioVenta?.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    p.manejaInventario == true
                        ? (p.stockActual?.toStringAsFixed(2) ?? '0.00')
                        : 'N/A',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          (p.stockActual ?? 0) <= (p.stockMinimo ?? 0) &&
                              p.manejaInventario == true
                          ? Colors.red
                          : Colors.black87,
                    ),
                  ),
                ),
                if (isAdmin) ...[
                  DataCell(
                    Text(
                      'RD\$ ${p.costo?.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  DataCell(_buildStatusBadge(p.activo ?? true)),
                ],
                if (auth.hasPermission('editar_productos'))
                  DataCell(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_rounded,
                          color: Colors.indigo,
                          onPressed: () => onEdit(p),
                        ),
                        if (auth.hasPermission('eliminar_productos'))
                          _buildActionButton(
                            icon: Icons.delete_forever_rounded,
                            color: Colors.redAccent,
                            onPressed: () => onDelete(p),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String? cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        cat ?? 'GENERAL',
        style: const TextStyle(
          color: Colors.blue,
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
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      ),
    );
  }
}
