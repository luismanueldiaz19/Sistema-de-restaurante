import 'package:flutter/material.dart';
import '../../models/compra.dart';
import '../../../utils/helpers.dart';
import '../../../palletes/app_colors.dart';

class CompraDetallePanel extends StatelessWidget {
  final Compra? compra;
  final bool isLoading;

  const CompraDetallePanel({
    super.key,
    required this.compra,
    required this.isLoading,
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

    if (compra == null) {
      return Container(
        decoration: _panelDecoration(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Selecciona una compra',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Los detalles aparecerán aquí',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          // CABECERA DEL DETALLE
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalles de Compra',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Factura #${compra!.numeroFacturaProveedor}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.secondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: compra!.estado == 'PAGADA' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    compra!.estado,
                    style: TextStyle(
                      color: compra!.estado == 'PAGADA' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // INFO DEL PROVEEDOR Y FECHAS
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoDato('Proveedor', compra!.proveedor?.nombre ?? 'Desconocido', Icons.business),
                ),
                Expanded(
                  child: _buildInfoDato(
                    'Tipo', 
                    compra!.tipoCompra, 
                    Icons.credit_card
                  ),
                ),
                Expanded(
                  child: _buildInfoDato(
                    'Fecha', 
                    compra!.fechaCompra.toString().split(' ')[0], 
                    Icons.calendar_today_outlined
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // TABLA DE ARTICULOS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Artículos comprados',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary),
                ),
                const SizedBox(height: 16),
                if (compra!.detalles.isNotEmpty)
                  ...compra!.detalles.map((item) => _buildItemRow(item)),
                if (compra!.detalles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No hay artículos', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                  
                const SizedBox(height: 24),
                if (compra!.notas != null && compra!.notas!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.yellow.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                              const SizedBox(height: 4),
                              Text(compra!.notas!, style: TextStyle(color: Colors.orange.shade900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // TOTALES
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL DE COMPRA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(
                      formatCurrency(compra!.total),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary),
                    ),
                  ],
                ),
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
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildInfoDato(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.light,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(CompraDetalle item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${item.cantidad.toInt()}x',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.producto?.nombre ?? item.descripcion ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'RD\$ ${formatCurrency((item.costoUnitario * item.cantidad + item.impuestoMonto) / (item.cantidad > 0 ? item.cantidad : 1))} (Con ITBIS)',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(item.total),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
