import 'package:flutter/material.dart';
import '../../../model/factura.dart';
import '../../../palletes/app_colors.dart';
import 'package:intl/intl.dart';

class FacturaListItem extends StatelessWidget {
  final Factura factura;
  final bool isSelected;
  final VoidCallback onTap;

  const FacturaListItem({
    super.key,
    required this.factura,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final total = double.tryParse(factura.total ?? '0') ?? 0;
    
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
                Expanded(
                  child: Text(
                    'Factura #${factura.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildEstadoBadge(factura.estado ?? 'Desconocido'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Cliente: ${factura.cliente?.nombre ?? 'Consumidor Final'}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Fecha: ${factura.createdAt != null ? DateFormat('yyyy-MM-dd').format(factura.createdAt!) : 'N/A'}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              formatter.format(total),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    switch (estado.toUpperCase()) {
      case 'PAGADA':
        color = Colors.green;
        break;
      case 'ANULADA':
        color = Colors.red;
        break;
      case 'PENDIENTE':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
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
