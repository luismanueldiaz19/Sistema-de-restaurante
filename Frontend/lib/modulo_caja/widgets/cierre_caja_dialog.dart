import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../providers/caja_provider.dart';

class CierreCajaDialog extends StatefulWidget {
  final double montoEsperado;
  final List<dynamic> ventasPorMetodo;

  const CierreCajaDialog({
    super.key,
    required this.montoEsperado,
    this.ventasPorMetodo = const [],
  });

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authProvider);
    if (auth.token == null) return;

    final resumenResult = await ref
        .read(cajaProvider.notifier)
        .getResumen(auth.token!);

    if (!resumenResult['success']) {
      if (context.mounted) {
        showToast(
          context,
          'No tienes una sesión de caja abierta para cerrar.',
          bgColor: Colors.orange,
        );
      }
      return;
    }

    final double montoEsperado =
        (resumenResult['data']['monto_esperado_efectivo'] as num?)?.toDouble() ?? 0.0;

    final List<dynamic> ventasPorMetodo =
        resumenResult['data']['ventas_por_metodo'] ?? [];

    if (!context.mounted) return;

    final arqueoData = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CierreCajaDialog(
        montoEsperado: montoEsperado,
        ventasPorMetodo: ventasPorMetodo,
      ),
    );

    if (arqueoData == null) return;

    final result = await ref
        .read(cajaProvider.notifier)
        .cerrarCaja(
          token: auth.token!,
          montoFisico: (arqueoData['monto_fisico'] as num).toDouble(),
          desglose: Map<String, int>.from(arqueoData['desglose'] ?? {}),
          comentario: arqueoData['comentario'],
        );

    if (context.mounted) {
      if (result['success']) {
        showToast(context, 'CAJA CERRADA EXITOSAMENTE', bgColor: Colors.green);
      } else {
        showToast(context, 'Error: ${result['message']}', bgColor: Colors.red);
      }
    }
  }

  @override
  State<CierreCajaDialog> createState() => _CierreCajaDialogState();
}

class _CierreCajaDialogState extends State<CierreCajaDialog> {
  final Map<int, TextEditingController> _controllers = {};
  final List<int> _denominaciones = [
    2000,
    1000,
    500,
    200,
    100,
    50,
    25,
    10,
    5,
    1,
  ];
  final TextEditingController _comentarioController = TextEditingController();

  double _totalContado = 0;

  @override
  void initState() {
    super.initState();
    for (var d in _denominaciones) {
      _controllers[d] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    _comentarioController.dispose();
    super.dispose();
  }

  void _calcularTotal() {
    double total = 0;
    _controllers.forEach((denominacion, controller) {
      int cantidad = int.tryParse(controller.text) ?? 0;
      total += (denominacion * cantidad);
    });
    setState(() {
      _totalContado = total;
    });
  }

  void _limpiarTodo() {
    for (var c in _controllers.values) {
      c.clear();
    }
    _calcularTotal();
  }

  int get _totalPiezas {
    int total = 0;
    _controllers.forEach((_, c) {
      total += int.tryParse(c.text) ?? 0;
    });
    return total;
  }

  double get _diferencia => _totalContado - widget.montoEsperado;

  Color _getColorDenominacion(int valor) {
    switch (valor) {
      case 2000:
        return const Color(0xFFDC2626); // Rojo
      case 1000:
        return const Color(0xFF2563EB); // Azul
      case 500:
        return const Color(0xFF059669); // Verde
      case 200:
        return const Color(0xFFDB2777); // Rosado
      case 100:
        return const Color(0xFFD97706); // Naranja
      case 50:
        return const Color(0xFF7C3AED); // Morado
      default:
        return const Color(0xFF475569); // Slate para monedas
    }
  }

  bool _esMoneda(int valor) => valor <= 25;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: isDesktop ? 860 : size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.9,
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera compacta
            _buildHeader(context),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),

            // Contenido en 2 columnas (Escritorio) o Scroll (Móvil)
            Flexible(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna Izquierda: Denominaciones
                        Expanded(
                          flex: 11,
                          child: _buildDenominacionesSection(),
                        ),
                        const SizedBox(width: 14),

                        // Columna Derecha: Resumen de Cuadre
                        Expanded(
                          flex: 8,
                          child: SingleChildScrollView(
                            child: _buildRightSummaryPanel(),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildDenominacionesSection(),
                          const SizedBox(height: 14),
                          _buildRightSummaryPanel(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                size: 18,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Arqueo de Caja',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Desglose de efectivo en Pesos Dominicanos (RD\$)',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          splashRadius: 16,
          color: const Color(0xFF64748B),
        ),
      ],
    );
  }

  Widget _buildDenominacionesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'DESGLOSE DE EFECTIVO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_totalPiezas piezas',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            if (_totalContado > 0)
              InkWell(
                onTap: _limpiarTodo,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.refresh_rounded,
                        size: 12,
                        color: Color(0xFF64748B),
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Limpiar',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Grid de 2 columnas compacto para las 10 denominaciones
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 4.4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _denominaciones.length,
          itemBuilder: (context, index) {
            final d = _denominaciones[index];
            return _buildDenominacionCard(d);
          },
        ),
      ],
    );
  }

  Widget _buildDenominacionCard(int valor) {
    final color = _getColorDenominacion(valor);
    final esMoneda = _esMoneda(valor);
    final controller = _controllers[valor]!;
    final cantidad = int.tryParse(controller.text) ?? 0;
    final subtotal = cantidad * valor;
    final tieneCantidad = cantidad > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tieneCantidad
              ? color.withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
          width: tieneCantidad ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: tieneCantidad
                ? color.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge denominación
          Container(
            width: esMoneda ? 34 : 44,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(esMoneda ? 13 : 5),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$valor',
              style: TextStyle(
                fontSize: esMoneda ? 11 : 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '×',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),

          // Input de cantidad
          Container(
            width: 52,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: tieneCantidad ? color : const Color(0xFFCBD5E1),
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onTap: () {
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controller.text.length,
                );
              },
              onChanged: (_) => _calcularTotal(),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '=',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),

          // Subtotal
          Expanded(
            child: Text(
              FormatterNumber.formatCurrency(subtotal.toDouble()),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: tieneCantidad ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11.5,
                color: tieneCantidad
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSummaryPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: const [
              Icon(Icons.analytics_outlined, size: 15, color: Color(0xFF475569)),
              SizedBox(width: 6),
              Text(
                'RESUMEN DE CUADRE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Efectivo esperado
          _buildInfoMetricTile(
            label: 'EFECTIVO ESPERADO (SISTEMA)',
            subtitle: 'Ventas en efectivo + Base inicial',
            amount: FormatterNumber.formatCurrency(widget.montoEsperado),
            color: const Color(0xFF334155),
          ),
          const SizedBox(height: 8),

          // Total contado
          _buildInfoMetricTile(
            label: 'TOTAL CONTADO (FÍSICO)',
            subtitle: '$_totalPiezas piezas arqueadas',
            amount: FormatterNumber.formatCurrency(_totalContado),
            color: AppColors.primary,
            isHighlight: true,
          ),
          const SizedBox(height: 10),

          // Card de diferencia
          _buildDiferenciaCard(),

          // Si hay ventas por método
          if (widget.ventasPorMetodo.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildVentasPorMetodoSection(),
          ],

          const SizedBox(height: 12),
          const Text(
            'COMENTARIOS / OBSERVACIONES',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _comentarioController,
            maxLines: 2,
            style: const TextStyle(fontSize: 11.5),
            decoration: InputDecoration(
              hintText:
                  'Ej: Diferencia por cambio de monedas, billetes rotos...',
              hintStyle:
                  const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Botón Cerrar Caja
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _finalizarArqueo,
              icon: const Icon(Icons.lock_outline_rounded, size: 16),
              label: const Text(
                'CERRAR CAJA AHORA',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMetricTile({
    required String label,
    required String subtitle,
    required String amount,
    required Color color,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight
              ? AppColors.primary.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 13.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiferenciaCard() {
    final bool isExacto = _diferencia.abs() < 0.01;
    final bool isSobrante = _diferencia > 0.01;

    final Color bgColor = isExacto
        ? const Color(0xFFECFDF5)
        : (isSobrante ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2));

    final Color borderColor = isExacto
        ? const Color(0xFFA7F3D0)
        : (isSobrante ? const Color(0xFFBFDBFE) : const Color(0xFFFECACA));

    final Color textColor = isExacto
        ? const Color(0xFF065F46)
        : (isSobrante ? const Color(0xFF1E40AF) : const Color(0xFF991B1B));

    final IconData icon = isExacto
        ? Icons.check_circle_rounded
        : (isSobrante
            ? Icons.trending_up_rounded
            : Icons.warning_amber_rounded);

    final String title = isExacto
        ? 'CUADRE PERFECTO'
        : (isSobrante ? 'SOBRANTE EN CAJA' : 'FALTANTE EN CAJA');

    final String diffFormatted = isExacto
        ? 'RD\$ 0.00'
        : (isSobrante
            ? '+ ${FormatterNumber.formatCurrency(_diferencia)}'
            : '- ${FormatterNumber.formatCurrency(_diferencia.abs())}');

    final String desc = isExacto
        ? 'El dinero contado coincide con el sistema'
        : (isSobrante
            ? 'Hay más efectivo del registrado en sistema'
            : 'Falta efectivo respecto a lo esperado');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      diffFormatted,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentasPorMetodoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VENTAS DEL TURNO POR MÉTODO',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          ...widget.ventasPorMetodo.map((m) {
            final metodo =
                m['metodo_pago']?.toString().toUpperCase() ?? 'OTRO';
            final total =
                double.tryParse(m['total']?.toString() ?? '0') ?? 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    metodo,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  Text(
                    FormatterNumber.formatCurrency(total),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _finalizarArqueo() {
    Map<String, int> desglose = {};
    _controllers.forEach((key, value) {
      desglose[key.toString()] = int.tryParse(value.text) ?? 0;
    });

    Navigator.pop(context, {
      'monto_fisico': _totalContado,
      'desglose': desglose,
      'comentario': _comentarioController.text,
    });
  }
}
