import 'package:flutter/material.dart';
import '../../models/orden_compra_model.dart';
import '../../../utils/helpers.dart';
import '../../../palletes/app_colors.dart';

class OrdenCompraListItem extends StatelessWidget {
  final OrdenCompra ordenCompra;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPdfTap;
  final Function(String) onEstadoChange;

  const OrdenCompraListItem({
    super.key,
    required this.ordenCompra,
    required this.isSelected,
    required this.onTap,
    required this.onPdfTap,
    required this.onEstadoChange,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orden de Compra #${ordenCompra.id.toString().padLeft(6, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                _buildEstadoBadge(ordenCompra.estado ?? 'pendiente'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Proveedor: ${ordenCompra.proveedor?.nombre ?? 'Genérico'}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Fecha: ${ordenCompra.fechaEmision != null ? ordenCompra.fechaEmision!.toString().split(' ')[0] : ''}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatCurrency(double.tryParse(ordenCompra.total ?? '0') ?? 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                    fontSize: 16,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'pdf') {
                      onPdfTap();
                    } else {
                      onEstadoChange(val);
                    }
                  },
                  itemBuilder: (ctx) {
                    final items = <PopupMenuEntry<String>>[
                      const PopupMenuItem(value: 'pdf', child: Text('Descargar PDF')),
                    ];
                    
                    if (ordenCompra.estado != 'RECIBIDA') {
                      items.addAll([
                        const PopupMenuItem(value: 'BORRADOR', child: Text('Marcar como Borrador')),
                        const PopupMenuItem(value: 'ENVIADA', child: Text('Marcar como Enviada')),
                        const PopupMenuItem(value: 'CANCELADA', child: Text('Marcar Cancelada', style: TextStyle(color: Colors.red))),
                      ]);
                    }
                    return items;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    switch (estado) {
      case 'aprobado':
        color = Colors.green;
        break;
      case 'cancelado':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}



