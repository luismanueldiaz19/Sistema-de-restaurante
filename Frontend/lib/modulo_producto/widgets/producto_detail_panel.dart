import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../../palletes/app_colors.dart';

class ProductoDetailPanel extends StatelessWidget {
  final Producto producto;

  const ProductoDetailPanel({super.key, required this.producto});

  Widget _buildInfoRow(IconData icon, String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.azulOscuro.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.azulOscuro),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : "N/A",
                  style: TextStyle(
                    fontSize: 15,
                    color: valueColor ?? AppColors.azulOscuro,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.azulOscuro.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 40,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre ?? "Sin Nombre",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (producto.activo ?? false)
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (producto.activo ?? false) ? "Activo" : "Inactivo",
                          style: TextStyle(
                            color: (producto.activo ?? false) ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna 1
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Información General",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          Icons.qr_code,
                          "Código",
                          producto.codigo ?? "",
                        ),
                        _buildInfoRow(
                          Icons.description_outlined,
                          "Descripción",
                          producto.descripcion ?? "",
                        ),
                        _buildInfoRow(
                          Icons.category_outlined,
                          "Categoría",
                          producto.categoria?.nombre ?? "",
                        ),
                        _buildInfoRow(
                          Icons.merge_type,
                          "Tipo Producto",
                          producto.tipoProducto ?? "",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  // Columna 2
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Detalles de Precio e Inventario",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          Icons.attach_money,
                          "Precio de Venta",
                          "RD\$ ${producto.precioVenta?.toStringAsFixed(2) ?? '0.00'}",
                          valueColor: Colors.green.shade700,
                        ),
                        _buildInfoRow(
                          Icons.money_off,
                          "Costo",
                          "RD\$ ${producto.costo?.toStringAsFixed(2) ?? '0.00'}",
                        ),
                        _buildInfoRow(
                          Icons.inventory_outlined,
                          "Stock Mínimo",
                          producto.stockMinimo?.toString() ?? "0",
                        ),
                        _buildInfoRow(
                          Icons.account_balance_outlined,
                          "Tipo Contable",
                          producto.tipoContable ?? "",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
