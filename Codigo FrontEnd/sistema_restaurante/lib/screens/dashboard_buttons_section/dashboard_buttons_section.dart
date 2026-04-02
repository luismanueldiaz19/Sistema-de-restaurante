import 'package:flutter/material.dart';
import '../../widgets/dashboard_button.dart';

class DashboardButtonsSection extends StatelessWidget {
  final void Function(String action) onAction;

  const DashboardButtonsSection({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 3.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          DashboardButton(
            title: 'Nueva Venta',
            icon: Icons.shopping_cart,
            color: Colors.green,
            onTap: () => onAction('venta'),
          ),
          DashboardButton(
            title: 'Clientes',
            icon: Icons.person,
            color: Colors.blue,
            onTap: () => onAction('clientes'),
          ),
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
        ],
      ),
    );
  }
}
