import 'package:flutter/material.dart';
import '../../models/cotizacion_model.dart';
import '../../../utils/helpers.dart';
import '../../../palletes/app_colors.dart';

class CotizacionListItem extends StatelessWidget {
  final Cotizacion cotizacion;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPdfTap;
  final Function(String) onEstadoChange;

  const CotizacionListItem({
    super.key,
    required this.cotizacion,
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
                  'Cotización #${cotizacion.id.toString().padLeft(6, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                _buildEstadoBadge(cotizacion.estado ?? 'pendiente'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${cotizacion.cliente?.nombre ?? 'Genérico'}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Fecha: ${cotizacion.fechaEmision != null ? cotizacion.fechaEmision!.toString().split(' ')[0] : ''}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatCurrency(double.tryParse(cotizacion.total ?? '0') ?? 0),
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
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'pdf', child: Text('Ver PDF')),
                    const PopupMenuItem(value: 'aprobado', child: Text('Marcar Aprobado')),
                    const PopupMenuItem(value: 'pendiente', child: Text('Marcar Pendiente')),
                    const PopupMenuItem(value: 'cancelado', child: Text('Marcar Cancelado', style: TextStyle(color: Colors.red))),
                  ],
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
