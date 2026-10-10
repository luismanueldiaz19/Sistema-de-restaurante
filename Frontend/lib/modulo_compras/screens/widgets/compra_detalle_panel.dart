import 'package:flutter/material.dart';
import '../../models/compra.dart';
import '../../../utils/helpers.dart';
import '../../../palletes/app_colors.dart';
import 'pagos_compra_dialog.dart';

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
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
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
              Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Selecciona una compra',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Los detalles aparecerán aquí',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
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
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Factura #${compra!.numeroFacturaProveedor}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (compra!.estado != 'PENDIENTE')
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => PagosCompraDialog(
                              compraId: compra!.id,
                              totalCompra: compra!.total,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.history,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Ver Pagos',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: compra!.estado == 'PAGADA'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        compra!.estado,
                        style: TextStyle(
                          color: compra!.estado == 'PAGADA'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // INFO DEL PROVEEDOR Y FECHAS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoDato(
                    'Proveedor',
                    compra!.proveedor?.nombre ?? 'Desconocido',
                    Icons.business,
                  ),
                ),
                Expanded(
                  child: _buildInfoDato(
                    'Tipo',
                    compra!.tipoCompra,
                    Icons.credit_card,
                  ),
                ),
                Expanded(
                  child: _buildInfoDato(
                    'Fecha',
                    compra!.fechaCompra.toString().split(' ')[0],
                    Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoDato(
                    'Comprobante (NCF)',
                    compra!.ncf?.isNotEmpty == true ? compra!.ncf! : 'N/A',
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildInfoDato(
                    'Registrado por',
                    compra!.usuario?.name ?? 'Desconocido',
                    Icons.person_outline,
                  ),
                ),
                Expanded(
                  child:
                      const SizedBox(), // Espacio en blanco para balancear las 3 columnas
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // TABLA DE ARTICULOS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Artículos comprados',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                // Encabezados de tabla
                if (compra!.detalles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 40), // Espacio para el badge de cantidad
                        const Expanded(
                          flex: 3,
                          child: Text('Producto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text('Precio', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text('ITBIS', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (compra!.detalles.isNotEmpty)
                  ...compra!.detalles.map((item) => _buildItemRow(item)),
                if (compra!.detalles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No hay artículos',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                if (compra!.notas != null && compra!.notas!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.yellow.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes,
                          color: Colors.orange.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                compra!.notas!,
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 12,
                                ),
                              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL DE COMPRA',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Text(
                  FormatterNumber.formatCurrency(compra!.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
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
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildInfoDato(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.light,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(CompraDetalle item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${item.cantidad.toInt()}x',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              item.producto?.nombre ?? item.descripcion ?? 'Desconocido',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              FormatterNumber.formatCurrency(item.costoUnitario),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              FormatterNumber.formatCurrency(item.impuestoMonto),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              FormatterNumber.formatCurrency(item.total),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
