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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
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
                    'Factura #${compra.numeroFacturaProveedor}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildEstadoBadge(compra.estado),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(isContado ? Icons.money : Icons.credit_card, size: 14, color: isContado ? Colors.green : Colors.orange),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Proveedor: ${compra.proveedor?.nombre ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Fecha: ${compra.fechaCompra.toLocal().toString().split(' ')[0]}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              formatCurrency(compra.total),
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
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
