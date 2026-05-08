import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart'; // 🔥 Importar helpers
import '../models/factura_item.dart';

class CarritoLista extends StatelessWidget {
  final List<FacturaItem> items;
  final Function(String, double) onUpdateCantidad;
  final Function(String) onRemove;

  const CarritoLista({
    super.key,
    required this.items,
    required this.onUpdateCantidad,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'El carrito está vacío',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItem(item);
      },
    );
  }

  Widget _buildItem(FacturaItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.descripcion,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    Text(
                      '${formatCurrency(item.precio)} / unidad',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onRemove(item.id),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Control de Cantidad
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildQtyBtn(
                      Icons.remove,
                      () => onUpdateCantidad(item.id, item.cantidad - 1),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        item.cantidad.toInt().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildQtyBtn(
                      Icons.add,
                      () => onUpdateCantidad(item.id, item.cantidad + 1),
                    ),
                  ],
                ),
              ),
              // Totales por línea
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.montoDescuento > 0)
                    Text(
                      '- ${formatCurrency(item.montoDescuento)}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text(
                    formatCurrency(item.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 18, color: AppColors.azulOscuro),
      ),
    );
  }
}
