import 'package:flutter/material.dart';

import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../providers/mesas_provider.dart';

class MesaMetricsBar extends StatelessWidget {
  final MesasProvider state;
  final double totalConsumo;

  const MesaMetricsBar({
    super.key,
    required this.state,
    required this.totalConsumo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMetricItem(
              'Total Mesas',
              '${state.totalMesas}',
              Icons.table_restaurant,
              Colors.grey.shade800,
            ),
            _buildMetricDivider(),
            _buildMetricItem(
              'Libres',
              '${state.mesasLibres}',
              Icons.check_circle_outline,
              Colors.green.shade700,
            ),
            _buildMetricDivider(),
            _buildMetricItem(
              'Ocupadas',
              '${state.mesasOcupadas}',
              Icons.dining_outlined,
              Colors.orange.shade800,
            ),
            _buildMetricDivider(),
            _buildMetricItem(
              'Por Cobrar',
              '${state.mesasPorCobrar}',
              Icons.receipt_long,
              Colors.blue.shade700,
            ),
            _buildMetricDivider(),
            _buildMetricItem(
              'Consumo',
              FormatterNumber.formatCurrency(totalConsumo),
              Icons.payments_outlined,
              AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      height: 16,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.grey.shade200,
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
