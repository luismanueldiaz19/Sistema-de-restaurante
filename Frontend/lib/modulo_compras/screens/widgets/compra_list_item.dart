import 'package:flutter/material.dart';
import '../../models/compra.dart';
import '../../../utils/helpers.dart';
import '../../../palletes/app_colors.dart';

class CompraListItem extends StatelessWidget {
  final Compra compra;
  final bool isSelected;
  final VoidCallback onTap;

  const CompraListItem({
    super.key,
    required this.compra,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isContado = compra.tipoCompra == 'CONTADO';
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
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
                    'Factura #${compra.numeroFacturaProveedor}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildEstadoBadge(compra.estado),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(isContado ? Icons.money : Icons.credit_card, size: 12, color: isContado ? Colors.green : Colors.orange),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Proveedor: ${compra.proveedor?.nombre ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Fecha: ${compra.fechaCompra.toLocal().toString().split(' ')[0]}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency(compra.total),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
                fontSize: 14,
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
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
