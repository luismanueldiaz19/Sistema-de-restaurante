import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';

class CierreCajaDialog extends StatefulWidget {
  final double montoEsperado;
  final List<dynamic> ventasPorMetodo;

  const CierreCajaDialog({
    super.key,
    required this.montoEsperado,
    this.ventasPorMetodo = const [],
  });

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

  double get _diferencia => _totalContado - widget.montoEsperado;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: isDesktop ? 900 : size.width * 0.9,
        height: size.height * 0.85,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Arqueo de Caja',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Desglose de efectivo en Pesos Dominicanos (RD\$)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lado Izquierdo: Denominaciones
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lado Izquierdo: Denominaciones
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.only(right: 24),
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 2.8,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: _denominaciones.length,
                              itemBuilder: (context, index) {
                                final d = _denominaciones[index];
                                return _buildDenominacionRow(d);
                              },
                            ),
                          ),
                        ),

                        // Lado Derecho: Resumen y Resultado (Con Scroll para evitar overflow)
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.ventasPorMetodo.isNotEmpty) ...[
                                    const Text(
                                      'RESUMEN DE VENTAS DEL TURNO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...widget.ventasPorMetodo.map((m) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Text(
                                                m['metodo_pago']
                                                    .toString()
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '\$${double.parse(m['total'].toString()).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                    const Divider(height: 32),
                                  ],
                                  _buildSummaryItem(
                                    'EFECTIVO ESPERADO EN CAJA',
                                    '\$${widget.montoEsperado.toStringAsFixed(2)}',
                                    Colors.grey.shade700,
                                    isMain: false,
                                  ),
                                  const Divider(height: 40),
                                  _buildSummaryItem(
                                    'TOTAL CONTADO',
                                    '\$${_totalContado.toStringAsFixed(2)}',
                                    AppColors.primary,
                                    isMain: true,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildDiferenciaCard(),
                                  const SizedBox(height: 32),
                                  const Text(
                                    'COMENTARIOS / OBSERVACIONES',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _comentarioController,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Ej: Diferencia por cambio de monedas...',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 60,
                                    child: ElevatedButton(
                                      onPressed: _finalizarArqueo,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'CERRAR CAJA AHORA',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    );
  }

  Widget _buildDenominacionRow(int valor) {
    // Definición de colores por denominación (Pesos Dominicanos)
    Color colorBillete;
    switch (valor) {
      case 2000:
        colorBillete = const Color(0xFFD4314A);
        break; // Rojo/Rosado
      case 1000:
        colorBillete = const Color(0xFF1B4E9B);
        break; // Azul
      case 500:
        colorBillete = const Color(0xFF3B7E41);
        break; // Verde
      case 200:
        colorBillete = const Color(0xFFBC6BA6);
        break; // Rosado/Lila
      case 100:
        colorBillete = const Color(0xFFE8833A);
        break; // Naranja
      case 50:
        colorBillete = const Color(0xFF7B52A1);
        break; // Morado
      default:
        colorBillete = Colors.blueGrey; // Monedas
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorBillete.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorBillete.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 35,
            decoration: BoxDecoration(
              color: colorBillete.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorBillete.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                valor.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorBillete,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'x',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controllers[valor],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colorBillete),
                ),
              ),
              onChanged: (_) => _calcularTotal(),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '= \$${((int.tryParse(_controllers[valor]!.text) ?? 0) * valor).toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color, {
    required bool isMain,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isMain ? 32 : 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDiferenciaCard() {
    final bool isError = _diferencia != 0;
    final Color color = _diferencia == 0
        ? Colors.green
        : (_diferencia > 0 ? Colors.blue : Colors.red);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            _diferencia == 0
                ? Icons.check_circle_rounded
                : (_diferencia > 0
                      ? Icons.add_circle_rounded
                      : Icons.warning_rounded),
            color: color,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _diferencia == 0
                    ? 'CUADRE PERFECTO'
                    : (_diferencia > 0 ? 'SOBRANTE' : 'FALTANTE'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '\$${_diferencia.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
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
