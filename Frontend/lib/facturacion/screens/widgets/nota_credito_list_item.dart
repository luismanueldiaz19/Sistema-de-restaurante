import 'package:flutter/material.dart';
import '../../../model/nota_credito_model.dart';
import '../../../utils/helpers.dart';
import '../../../palletes/app_colors.dart';

class NotaCreditoListItem extends StatelessWidget {
  final NotaCreditoModel nota;
  final bool isSelected;
  final VoidCallback onTap;

  const NotaCreditoListItem({
    super.key,
    required this.nota,
    required this.isSelected,
    required this.onTap,
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
                  'Nota Crédito #${nota.id.toString().padLeft(6, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'APLICADA',
                    style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${nota.factura?.cliente?.nombre ?? 'Desconocido'}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Fecha: ${nota.createdAt != null ? nota.createdAt!.toString().split(' ')[0] : ''}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              formatCurrency(double.tryParse(nota.totalDevolucion ?? '0') ?? 0),
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
}
