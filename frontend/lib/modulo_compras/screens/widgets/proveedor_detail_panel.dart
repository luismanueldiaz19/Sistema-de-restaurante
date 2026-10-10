import 'package:flutter/material.dart';
import '../../../palletes/app_colors.dart';
import '../../models/proveedor.dart';
import '../../../modulo_cliente/widgets/client_detail_item.dart'; // Reusing this generic widget
import '../../../../utils/get_initials.dart';

class ProveedorDetailPanel extends StatelessWidget {
  final Proveedor proveedor;

  const ProveedorDetailPanel({super.key, required this.proveedor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner/Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.02),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 20,
                  child: Text(
                    InitialsHelper.getInitials(proveedor.nombre, defaultChar: "P"),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proveedor.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (proveedor.activo)
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (proveedor.activo)
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              (proveedor.activo) ? "Activo" : "Inactivo",
                              style: TextStyle(
                                color: (proveedor.activo)
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (proveedor.esInformal)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                "Informal",
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    Icons.store_mall_directory_outlined,
                    "Información del Proveedor",
                  ),
                  const SizedBox(height: 12),
                  _buildInfoGrid([
                    ClientDetailItem(
                      icon: Icons.badge_outlined,
                      label: "RNC",
                      value:
                          (proveedor.rnc != null && proveedor.rnc!.isNotEmpty)
                          ? proveedor.rnc!
                          : "N/A",
                    ),
                    ClientDetailItem(
                      icon: Icons.email_outlined,
                      label: "Email",
                      value:
                          (proveedor.email != null &&
                              proveedor.email!.isNotEmpty)
                          ? proveedor.email!
                          : "N/A",
                    ),
                    ClientDetailItem(
                      icon: Icons.phone_outlined,
                      label: "Teléfono",
                      value:
                          (proveedor.telefono != null &&
                              proveedor.telefono!.isNotEmpty)
                          ? proveedor.telefono!
                          : "N/A",
                    ),
                    ClientDetailItem(
                      icon: Icons.location_on_outlined,
                      label: "Dirección",
                      value:
                          (proveedor.direccion != null &&
                              proveedor.direccion!.isNotEmpty)
                          ? proveedor.direccion!
                          : "N/A",
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: constraints.maxWidth > 500 ? 4 : 5,
          children: items,
        );
      },
    );
  }
}
