import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_button.dart';

class DashboardButtonsSection extends ConsumerWidget {
  final void Function(String action) onAction;

  const DashboardButtonsSection({super.key, required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final items = [
      if (auth.hasPermission('crear_facturas'))
        DashboardButton(
          title: 'Vender',
          icon: Icons.add_shopping_cart_rounded,
          color: Colors.green.shade600,
          onTap: () => onAction('venta'),
        ),
      if (auth.hasPermission('ver_clientes'))
        DashboardButton(
          title: 'Clientes',
          icon: Icons.people_alt_rounded,
          color: AppColors.azulOscuro,
          onTap: () => onAction('clientes'),
        ),
      if (auth.hasPermission('ver_facturas'))
        DashboardButton(
          title: 'Reportes',
          icon: Icons.analytics_rounded,
          color: Colors.indigo,
          onTap: () => onAction('reportes'),
        ),
      if (auth.hasPermission('ver_gastos'))
        DashboardButton(
          title: 'Inventario',
          icon: Icons.inventory_rounded,
          color: Colors.orange.shade700,
          onTap: () => onAction('inventario'),
        ),
    ];
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth;

            // Ajuste de columnas según el ancho
            int crossAxisCount = (width / 160).floor();
            if (crossAxisCount < 2) crossAxisCount = 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.05, // 👈 Más cuadrado para el nuevo diseño
              ),
              itemBuilder: (context, index) => items[index],
            );
          },
        ),
      ),
    );
  }
}
