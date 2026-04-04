import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_button.dart';

class DashboardButtonsSection extends StatelessWidget {
  final void Function(String action) onAction;

  const DashboardButtonsSection({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final items = [
      DashboardButton(
        title: 'Nueva Venta',
        icon: Icons.shopping_cart,
        color: Colors.green,
        onTap: () => onAction('venta'),
      ),
      // if (auth.permissions.contains("ver_clientes"))
      DashboardButton(
        title: 'Clientes',
        icon: Icons.person,
        color: Colors.blue,
        onTap: () => onAction('clientes'),
      ),
      if (auth.permissions.contains("ver_clientes"))
        DashboardButton(
          title: 'Productos',
          icon: Icons.inventory_2,
          color: Colors.orange,
          onTap: () => onAction('productos'),
        ),
      DashboardButton(
        title: 'Reportes',
        icon: Icons.bar_chart,
        color: Colors.purple,
        onTap: () => onAction('reportes'),
      ),
      DashboardButton(
        title: 'Inventario',
        icon: Icons.assignment,
        color: Colors.red,
        onTap: () => onAction('inventario'),
      ),
      DashboardButton(
        title: 'Cuentas por Cobrar',
        icon: Icons.account_balance_wallet,
        color: Colors.teal,
        onTap: () => onAction('cxc'),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;

          // 👇 tamaño ideal de cada item
          int crossAxisCount = (width / 150).floor();

          // mínimo 2 columnas
          if (crossAxisCount < 2) crossAxisCount = 2;

          return GridView.builder(
            shrinkWrap: true,
            // crossAxisCount: 3,
            // mainAxisSpacing: 10,
            // crossAxisSpacing: 5,
            // childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 5,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              return items[index];
            },
          );
        },
      ),
    );
  }
}
