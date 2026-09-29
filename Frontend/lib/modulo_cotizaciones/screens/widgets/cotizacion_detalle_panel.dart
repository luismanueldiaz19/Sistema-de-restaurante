import 'package:flutter/material.dart';
import 'package:sistema_restaurante/utils/constants.dart';
import '../../models/cotizacion_model.dart';
import '../../../utils/helpers.dart';
import '../../../palletes/app_colors.dart';

class CotizacionDetallePanel extends StatelessWidget {
  final Cotizacion? cotizacion;
  final bool isLoading;
  final VoidCallback onPdfTap;

  const CotizacionDetallePanel({
    super.key,
    required this.cotizacion,
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

    if (cotizacion == null) {
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
                'Selecciona una cotización',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // MARCA DE AGUA
          Opacity(
            opacity: 0.05,
            child: Image.asset(
              logoFactura,
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
          ),
          // CONTENIDO PRINCIPAL
          Column(
            children: [
              // CABECERA DEL DETALLE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles de Cotización',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${cotizacion!.id.toString().padLeft(6, '0')}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: onPdfTap,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text(
                        'Descargar',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // INFO DEL CLIENTE Y FECHAS
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoDato(
                        'Cliente',
                        cotizacion!.cliente?.nombre ?? 'Genérico',
                        Icons.person_outline,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoDato(
                        'Emisión',
                        cotizacion!.fechaEmision?.toString().split(' ')[0] ??
                            'N/A',
                        Icons.calendar_today_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoDato(
                        'Vencimiento',
                        cotizacion!.fechaVencimiento?.toString().split(
                              ' ',
                            )[0] ??
                            'N/A',
                        Icons.event_busy_outlined,
                      ),
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
                      'Artículos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (cotizacion!.detalles != null)
                      ...cotizacion!.detalles!.map(
                        (item) => _buildItemRow(item),
                      ),
                    if (cotizacion!.detalles == null ||
                        cotizacion!.detalles!.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No hay artículos en esta cotización',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),

                    const SizedBox(height: 24),
                    if (cotizacion!.nota != null &&
                        cotizacion!.nota!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.yellow.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.notes,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nota',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cotizacion!.nota!,
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50.withValues(
                    alpha: 0.8,
                  ), // Semi-transparent for watermark visibility
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    _buildTotalRow(
                      'Subtotal',
                      double.tryParse(cotizacion!.subtotal ?? '0') ?? 0,
                    ),
                    const SizedBox(height: 8),
                    _buildTotalRow(
                      'Descuento',
                      double.tryParse(cotizacion!.descuentoTotal ?? '0') ?? 0,
                      isDiscount: true,
                    ),
                    const SizedBox(height: 8),
                    _buildTotalRow(
                      'ITBIS (18%)',
                      double.tryParse(cotizacion!.itbis ?? '0') ?? 0,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL GENERAL',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          formatCurrency(
                            double.tryParse(cotizacion!.total ?? '0') ?? 0,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
          color: Colors.black.withValues(alpha: 0.05),
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
          padding: const EdgeInsets.all(8),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
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

  Widget _buildItemRow(CotizacionDetalle item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${double.tryParse(item.cantidad ?? '0')?.toInt() ?? 0}x',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descripcion ?? 'Desconocido',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'RD\$ ${item.precio}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(double.tryParse(item.total ?? '0') ?? 0),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        Text(
          '${isDiscount ? '- ' : ''}${formatCurrency(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isDiscount ? Colors.red : AppColors.secondary,
          ),
        ),
      ],
    );
  }
}
