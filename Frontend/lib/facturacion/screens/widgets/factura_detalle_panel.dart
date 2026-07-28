import 'package:flutter/material.dart';
import '../../../model/factura.dart';
import '../../../palletes/app_colors.dart';
import 'package:intl/intl.dart';
import '../nota_credito_dialog.dart';

class FacturaDetallePanel extends StatelessWidget {
  final Factura? factura;
  final bool isLoading;

  const FacturaDetallePanel({
    super.key,
    required this.factura,
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

    if (factura == null) {
      return Container(
        decoration: _panelDecoration(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Selecciona una factura',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Los detalles y acciones aparecerán aquí',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final formatter = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final total = double.tryParse(factura!.total ?? '0') ?? 0;

    // Status color
    Color statusColor = Colors.grey;
    if (factura!.estado?.toLowerCase() == 'pagada') statusColor = Colors.green;
    if (factura!.estado?.toLowerCase() == 'pendiente')
      statusColor = Colors.orange;
    if (factura!.estado?.toLowerCase() == 'anulada') statusColor = Colors.red;

    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          // CABECERA DEL DETALLE
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
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
                      'Detalles de Factura',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Factura #${factura!.id}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (factura!.estado ?? 'Desconocido').toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // INFO DEL CLIENTE Y FECHAS
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoDato(
                    'Cliente',
                    factura!.cliente?.nombre ?? 'Consumidor Final',
                    Icons.person,
                  ),
                ),
                Expanded(
                  child: _buildInfoDato(
                    'Tipo',
                    factura!.tipoFactura?.toUpperCase() ?? 'CONTADO',
                    Icons.credit_card,
                  ),
                ),
                Expanded(
                  child: _buildInfoDato(
                    'Fecha',
                    factura!.createdAt != null
                        ? DateFormat('yyyy-MM-dd').format(factura!.createdAt!)
                        : 'N/A',
                    Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoDato(
                    'Comprobante (NCF)',
                    factura!.ncf?.isNotEmpty == true ? factura!.ncf! : 'N/A',
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildInfoDato(
                    'Registrado por',
                    factura!.user?.name ?? 'Administrador',
                    Icons.person_outline,
                  ),
                ),
                Expanded(child: const SizedBox()),
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
                  'Artículos vendidos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (factura!.detalles != null && factura!.detalles!.isNotEmpty)
                  ...factura!.detalles!.map(
                    (item) => _buildItemRow(item, formatter),
                  ),
                if (factura!.detalles == null || factura!.detalles!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No hay artículos',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),

                const SizedBox(height: 32),

                // GRILLA DE ACCIONES
                const Text(
                  'Acciones del Documento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildActionButton(
                      context,
                      Icons.visibility,
                      'Ver Factura',
                      Colors.blue,
                      () {},
                    ),
                    _buildActionButton(
                      context,
                      Icons.print,
                      'Imprimir',
                      Colors.grey.shade700,
                      () {},
                    ),
                    _buildActionButton(
                      context,
                      Icons.payment,
                      'Pago',
                      Colors.green,
                      () {},
                    ),
                    _buildActionButton(
                      context,
                      Icons.share,
                      'Compartir',
                      Colors.orange,
                      () {},
                    ),
                    _buildActionButton(
                      context,
                      Icons.remove_circle_outline,
                      'Nota Crédito',
                      Colors.purple,
                      () {
                        showDialog(
                          context: context,
                          builder: (_) => NotaCreditoDialog(factura: factura!),
                        );
                      },
                    ),
                    _buildActionButton(
                      context,
                      Icons.add_circle_outline,
                      'Nota Débito',
                      Colors.teal,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Módulo de Nota de Débito en desarrollo',
                            ),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      context,
                      Icons.assignment_return,
                      'Devolución',
                      Colors.brown,
                      () {},
                    ),
                    _buildActionButton(
                      context,
                      Icons.cancel,
                      'Anular',
                      Colors.red,
                      () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TOTALES
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL DE FACTURA',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  formatter.format(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
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

  Widget _buildInfoDato(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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

  Widget _buildItemRow(dynamic item, NumberFormat formatter) {
    // Tratamos el item según si es map o modelo dependiendo de cómo venga en factura!.detalles
    final desc =
        item.descripcion ?? item.producto?.nombre ?? 'Producto sin nombre';
    final cant = double.tryParse(item.cantidad?.toString() ?? '0') ?? 0;
    final precio = double.tryParse(item.precio?.toString() ?? '0') ?? 0;
    final itbis = double.tryParse(item.itbis?.toString() ?? '0') ?? 0;
    final totalLinea = double.tryParse(item.total?.toString() ?? '0') ?? (cant * precio + itbis);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${cant.toInt()}x',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatter.format(precio)} (ITBIS: ${formatter.format(itbis)})',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatter.format(totalLinea),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
