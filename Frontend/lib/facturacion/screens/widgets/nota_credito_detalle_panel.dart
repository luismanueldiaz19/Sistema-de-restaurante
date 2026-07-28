import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../model/nota_credito_model.dart';
import '../../../palletes/app_colors.dart';

class NotaCreditoDetallePanel extends StatelessWidget {
  final NotaCreditoModel? nota;
  final bool isLoading;
  final VoidCallback onPdfTap;

  const NotaCreditoDetallePanel({
    super.key,
    required this.nota,
    required this.isLoading,
    required this.onPdfTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: _panelDecoration(),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (nota == null) {
      return Container(
        decoration: _panelDecoration(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Selecciona una nota de crédito',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final formatter = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final total = double.tryParse(nota!.totalDevolucion ?? '0') ?? 0;

    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detalles de Nota de Crédito', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('NCF: ${nota!.ncf ?? 'N/A'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.secondary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onPdfTap,
                  icon: const Icon(Icons.print),
                  label: const Text('Ver PDF'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(child: _buildInfoDato('Cliente', nota!.factura?.cliente?.nombre ?? 'Desconocido', Icons.person)),
                Expanded(child: _buildInfoDato('Factura Afectada', 'Factura #${nota!.facturaId}', Icons.receipt)),
                Expanded(child: _buildInfoDato('Motivo', nota!.motivo ?? 'N/A', Icons.info_outline)),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Artículos devueltos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary)),
                const SizedBox(height: 16),
                if (nota!.detalles != null && nota!.detalles!.isNotEmpty)
                  ...nota!.detalles!.map((item) => _buildItemRow(item, formatter)),
                if (nota!.detalles == null || nota!.detalles!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No hay detalles', style: TextStyle(color: Colors.grey.shade500)),
                  ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL DEVOLUCIÓN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.red)),
                Text(formatter.format(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDato(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(dynamic item, NumberFormat formatter) {
    final desc = item.descripcion ?? item.producto?.nombre ?? 'Producto sin nombre';
    final cant = double.tryParse(item.cantidad?.toString() ?? '0') ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text('${cant.toInt()}x', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, spreadRadius: 2)],
    );
  }
}
