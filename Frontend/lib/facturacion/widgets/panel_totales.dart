import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/factura_item.dart';

class PanelTotales extends StatelessWidget {
  final TotalesFactura totales;
  final VoidCallback onProcesar;
  final bool isLoading;
  final bool esCotizacion;
  final bool esOrdenCompra;
  final bool esPedido;
  final List<FacturaItem>? carrito;

  const PanelTotales({
    super.key,
    required this.totales,
    required this.onProcesar,
    this.isLoading = false,
    this.esCotizacion = false,
    this.esOrdenCompra = false,
    this.esPedido = false,
    this.carrito,
  });

  /// Genera la etiqueta ITBIS dinámica según las tasas del carrito.
  /// Si todos los items tienen la misma tasa → "ITBIS (18%)"
  /// Si hay tasas mixtas (ej: 0% y 18%) → "ITBIS"
  /// Si todo es 0% → "ITBIS (Exento)"
  String get _itbisLabel {
    if (carrito == null || carrito!.isEmpty) return 'ITBIS (18%)';
    final tasas = carrito!.map((i) => i.itbisPorcentaje).toSet();
    if (tasas.length == 1) {
      final tasa = tasas.first;
      return tasa == 0
          ? 'ITBIS (Exento)'
          : 'ITBIS (${tasa.toStringAsFixed(0)}%)';
    }
    return 'ITBIS';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow('Subtotal', formatCurrency(totales.subtotal)),
          const SizedBox(height: 12),
          _buildRow(
            'Descuento',
            '- ${formatCurrency(totales.descuento)}',
            isNegative: true,
          ),
          const SizedBox(height: 12),
          _buildRow(_itbisLabel, formatCurrency(totales.itbis)),
          const Divider(height: 32, color: Colors.white24, thickness: 1),
          _buildRow(
            'TOTAL A PAGAR',
            formatCurrency(totales.total),
            isTotal: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: (totales.total > 0 && !isLoading) ? onProcesar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      esPedido
                          ? 'PROCESAR PEDIDO'
                          : (esOrdenCompra
                                ? 'PROCESAR ORDEN'
                                : (esCotizacion
                                      ? 'PROCESAR COTIZACION'
                                      : 'PROCESAR FACTURA')),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isNegative = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.white70,
            fontSize: isTotal ? 16 : 14, // Reducimos un poco el tamaño base
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                color: isNegative ? Colors.redAccent : Colors.white,
                fontSize: isTotal ? 22 : 16,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
