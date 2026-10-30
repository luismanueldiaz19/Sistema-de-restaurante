import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../../utils/formatter_number.dart';

class EstadoResultadosHojaTable extends StatelessWidget {
  final List<Map<String, dynamic>> cuentasIngresos;
  final List<Map<String, dynamic>> cuentasCostos;
  final List<Map<String, dynamic>> cuentasGastos;
  final double totalIngresos;
  final double totalCostos;
  final double utilidadBruta;
  final double totalGastos;
  final double utilidadNeta;

  const EstadoResultadosHojaTable({
    super.key,
    required this.cuentasIngresos,
    required this.cuentasCostos,
    required this.cuentasGastos,
    required this.totalIngresos,
    required this.totalCostos,
    required this.utilidadBruta,
    required this.totalGastos,
    required this.utilidadNeta,
  });

  String _formatMonto(double monto) {
    if (monto < 0) {
      return '(${FormatterNumber.formatCurrency(monto.abs())})';
    }
    return FormatterNumber.formatCurrency(monto);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.azulOscuro,
        borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              'CÓDIGO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              'NOMBRE DE LA CUENTA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'NATURALEZA / RUBRO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              'SALDO (RD\$)',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBanner(String title, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
      color: accent.withValues(alpha: 0.09),
      child: Text(
        title,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  List<Widget> _buildAccountRows(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Text(
            'Sin cuentas con movimiento para este filtro.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ];
    }

    return List.generate(items.length, (i) {
      final item = items[i];
      final balance = FormatterNumber.parseDouble(item['balance']);
      final tipo = (item['tipo_cuenta'] ?? item['tipo'] ?? '').toString();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
        decoration: BoxDecoration(
          color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                (item['codigo'] ?? '').toString(),
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Consolas',
                  fontWeight: FontWeight.w700,
                  color: AppColors.azulOscuro,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                (item['nombre'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.azulOscuro,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                tipo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: tipo.contains('Menos')
                      ? Colors.red.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Text(
                _formatMonto(balance),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11.5,
                  fontFamily: 'Consolas',
                  fontWeight: FontWeight.w700,
                  color: balance < 0
                      ? Colors.red.shade700
                      : AppColors.azulOscuro,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSubtotalRow(String label, double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.azulOscuro,
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              _formatMonto(total),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Consolas',
                fontWeight: FontWeight.w900,
                color: AppColors.azulOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esGanancia = utilidadNeta >= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildSectionBanner('1. INGRESOS / VENTAS', Colors.green.shade800),
          ..._buildAccountRows(cuentasIngresos),
          _buildSubtotalRow('Subtotal Ingresos / Ventas', totalIngresos),
          _buildSectionBanner('2. COSTO DE VENTAS', AppColors.primaryDark),
          ..._buildAccountRows(cuentasCostos),
          _buildSubtotalRow('Subtotal Costo de Ventas', totalCostos),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFFE2E8F0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'UTILIDAD BRUTA (INGRESOS - COSTOS)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    _formatMonto(utilidadBruta),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontFamily: 'Consolas',
                      fontWeight: FontWeight.w900,
                      color: utilidadBruta >= 0
                          ? AppColors.azulOscuro
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildSectionBanner(
            '3. GASTOS OPERATIVOS Y ADMINISTRATIVOS',
            Colors.indigo.shade800,
          ),
          ..._buildAccountRows(cuentasGastos),
          _buildSubtotalRow('Subtotal Gastos Operativos', totalGastos),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: esGanancia
                  ? Colors.green.shade800
                  : Colors.red.shade800,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(9),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    esGanancia
                        ? 'UTILIDAD NETA DEL EJERCICIO'
                        : 'PÉRDIDA NETA DEL EJERCICIO',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: Text(
                    _formatMonto(utilidadNeta),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontFamily: 'Consolas',
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

