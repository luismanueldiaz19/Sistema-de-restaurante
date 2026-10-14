import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../utils/formatter_number.dart';
import '../providers/reportes_contables_provider.dart';

class EstadoResultadosTablaScreen extends ConsumerStatefulWidget {
  const EstadoResultadosTablaScreen({super.key});

  @override
  ConsumerState<EstadoResultadosTablaScreen> createState() =>
      _EstadoResultadosTablaScreenState();
}

class _EstadoResultadosTablaScreenState
    extends ConsumerState<EstadoResultadosTablaScreen> {
  DateTime _fechaDesde = DateTime(DateTime.now().year, 1, 1);
  DateTime _fechaHasta = DateTime.now();
  bool _incluirCeros = true;
  String _filtroTexto = '';
  final TextEditingController _searchController = TextEditingController();

  String _formatMonto(double monto) {
    if (monto < 0) {
      return "(${FormatterNumber.formatCurrency(monto.abs())})";
    }
    return FormatterNumber.formatCurrency(monto);
  }

  void _seleccionarFecha(BuildContext context, bool isDesde) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isDesde ? _fechaDesde : _fechaHasta,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        if (isDesde) {
          _fechaDesde = date;
        } else {
          _fechaHasta = date;
        }
      });
    }
  }

  void _setPeriodo(String tipo) {
    final now = DateTime.now();
    setState(() {
      if (tipo == 'mes') {
        _fechaDesde = DateTime(now.year, now.month, 1);
        _fechaHasta = now;
      } else if (tipo == 'anio') {
        _fechaDesde = DateTime(now.year, 1, 1);
        _fechaHasta = now;
      } else if (tipo == 'todo') {
        _fechaDesde = DateTime(2020, 1, 1);
        _fechaHasta = now;
      }
    });
  }

  List<Map<String, dynamic>> _extraerCuentasDetalle(List<dynamic> nodos) {
    List<Map<String, dynamic>> resultado = [];
    for (var n in nodos) {
      final map = Map<String, dynamic>.from(n as Map);
      final hijos = map['hijos'] as List<dynamic>?;
      if (map['es_detalle'] == true || hijos == null || hijos.isEmpty) {
        resultado.add(map);
      } else {
        resultado.addAll(_extraerCuentasDetalle(hijos));
      }
    }
    return resultado;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fDesde = DateFormat('yyyy-MM-dd').format(_fechaDesde);
    final fHasta = DateFormat('yyyy-MM-dd').format(_fechaHasta);
    final paramStr = "$fDesde|$fHasta|${_incluirCeros ? '1' : '0'}";
    final asyncData = ref.watch(estadoResultadosProvider(paramStr));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Estado de Resultados • Formato Contable Oficial',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F2942),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Copiar reporte al portapapeles',
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Reporte preparado para exportar a hoja de cálculo',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => ref.refresh(estadoResultadosProvider(paramStr)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 🛠️ BARRA DE FILTROS SUPERIOR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Selector Desde
                InkWell(
                  onTap: () => _seleccionarFecha(context, true),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Color(0xFF0F2942),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Desde: $fDesde',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Selector Hasta
                InkWell(
                  onTap: () => _seleccionarFecha(context, false),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Color(0xFF0F2942),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Hasta: $fHasta',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Atajos rápidos
                OutlinedButton(
                  onPressed: () => _setPeriodo('mes'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('Este Mes', style: TextStyle(fontSize: 12)),
                ),
                OutlinedButton(
                  onPressed: () => _setPeriodo('anio'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('Este Año', style: TextStyle(fontSize: 12)),
                ),
                // Checkbox incluir ceros
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _incluirCeros,
                      visualDensity: VisualDensity.compact,
                      onChanged: (val) {
                        setState(() => _incluirCeros = val ?? true);
                      },
                    ),
                    const Text(
                      'Ver todas las cuentas (incluyendo \$0)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                // Buscador rápido
                SizedBox(
                  width: 200,
                  height: 32,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _filtroTexto = val.trim().toLowerCase()),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Buscar cuenta...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 📊 CONTENEDOR PRINCIPAL TABULAR (ESTILO HOJA DE CÁLCULO)
          Expanded(
            child: asyncData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error al cargar reporte: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              data: (data) {
                final ingresosRaw = data['ingresos'] as List<dynamic>? ?? [];
                final costosRaw = data['costos'] as List<dynamic>? ?? [];
                final gastosRaw = data['gastos'] as List<dynamic>? ?? [];
                final totales = data['totales'] as Map<String, dynamic>? ?? {};

                var cuentasIngresos = _extraerCuentasDetalle(ingresosRaw);
                var cuentasCostos = _extraerCuentasDetalle(costosRaw);
                var cuentasGastos = _extraerCuentasDetalle(gastosRaw);

                if (_filtroTexto.isNotEmpty) {
                  cuentasIngresos = cuentasIngresos
                      .where(
                        (c) =>
                            c['codigo'].toString().toLowerCase().contains(
                              _filtroTexto,
                            ) ||
                            c['nombre'].toString().toLowerCase().contains(
                              _filtroTexto,
                            ),
                      )
                      .toList();
                  cuentasCostos = cuentasCostos
                      .where(
                        (c) =>
                            c['codigo'].toString().toLowerCase().contains(
                              _filtroTexto,
                            ) ||
                            c['nombre'].toString().toLowerCase().contains(
                              _filtroTexto,
                            ),
                      )
                      .toList();
                  cuentasGastos = cuentasGastos
                      .where(
                        (c) =>
                            c['codigo'].toString().toLowerCase().contains(
                              _filtroTexto,
                            ) ||
                            c['nombre'].toString().toLowerCase().contains(
                              _filtroTexto,
                            ),
                      )
                      .toList();
                }

                final totalIngresos = FormatterNumber.parseDouble(
                  totales['ingresos'],
                );
                final totalCostos = FormatterNumber.parseDouble(
                  totales['costos'],
                );
                final utilidadBruta = FormatterNumber.parseDouble(
                  totales['utilidad_bruta'],
                );
                final totalGastos = FormatterNumber.parseDouble(
                  totales['gastos'],
                );
                final utilidadNeta = FormatterNumber.parseDouble(
                  totales['utilidad_neta'],
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF0F2942),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. ENCABEZADO DE COLUMNAS (Navy Blue)
                            _buildTableHeader(),

                            // 2. SECCIÓN: INGRESOS / VENTAS
                            _buildSectionHeader('INGRESOS / VENTAS'),
                            ..._buildRows(cuentasIngresos),
                            _buildSubtotalRow('Subtotal VENTAS', totalIngresos),

                            // 3. SECCIÓN: COSTO DE VENTAS
                            _buildSectionHeader('COSTO DE VENTAS'),
                            ..._buildRows(cuentasCostos),
                            _buildSubtotalRow('Subtotal COSTOS', totalCostos),

                            // 4. FILA DESTACADA: UTILIDAD BRUTA
                            _buildHighlightRow(
                              'UTILIDAD BRUTA',
                              utilidadBruta,
                              const Color(0xFFE2E8F0),
                            ),

                            // 5. SECCIÓN: GASTOS OPERATIVOS Y ADMINISTRATIVOS
                            _buildSectionHeader(
                              'GASTOS OPERATIVOS Y ADMINISTRATIVOS',
                            ),
                            ..._buildRows(cuentasGastos),
                            _buildSubtotalRow('Subtotal GASTOS', totalGastos),

                            // 6. RESULTADO FINAL: UTILIDAD NETA / PÉRDIDA NETA
                            _buildFinalResultRow(utilidadNeta),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ENCABEZADO DE LA TABLA
  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFF0F2942),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: const [
          SizedBox(
            width: 110,
            child: Text(
              'CÓDIGO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'NOMBRE DE LA CUENTA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TIPO DE CUENTA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              'TOTAL (\$)',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BANNER DE SECCIÓN (Azul Marino con letras blancas)
  Widget _buildSectionHeader(String title) {
    return Container(
      color: const Color(0xFF1E3A8A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // FILAS DE DATOS ALTERNADAS
  List<Widget> _buildRows(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: const Text(
            'Sin movimientos registrados en este período',
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      ];
    }

    return List.generate(items.length, (index) {
      final item = items[index];
      final isEven = index % 2 == 0;
      final balance = FormatterNumber.parseDouble(item['balance']);
      final tipoCuenta = item['tipo_cuenta'] ?? item['tipo'] ?? '';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isEven ? const Color(0xFFEBF3FB) : Colors.white,

          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.7),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                item['codigo'] ?? '',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                item['nombre'] ?? '',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                tipoCuenta,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: tipoCuenta.contains('Menos')
                      ? Colors.red.shade700
                      : const Color(0xFF475569),
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
                  fontWeight: FontWeight.w600,
                  color: balance < 0
                      ? Colors.red.shade700
                      : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // FILA DE SUBTOTAL
  Widget _buildSubtotalRow(String label, double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(color: Colors.grey.shade400, width: 1),
          bottom: const BorderSide(color: Color(0xFF0F2942), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Color(0xFF0F2942),
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              _formatMonto(total),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: Color(0xFF0F2942),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FILA DESTACADA (Utilidad Bruta)
  Widget _buildHighlightRow(String label, double total, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: const Border(
          top: BorderSide(color: Color(0xFF0F2942), width: 1),
          bottom: BorderSide(color: Color(0xFF0F2942), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: Color(0xFF0F2942),
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              _formatMonto(total),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: total >= 0
                    ? const Color(0xFF0F2942)
                    : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FILA FINAL: UTILIDAD O PÉRDIDA NETA
  Widget _buildFinalResultRow(double utilidadNeta) {
    final esGanancia = utilidadNeta >= 0;
    final bg = esGanancia ? const Color(0xFF14532D) : const Color(0xFF991B1B);
    final label = esGanancia
        ? 'UTILIDAD NETA DEL EJERCICIO'
        : 'PÉRDIDA NETA DEL EJERCICIO';

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Text(
              _formatMonto(utilidadNeta),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
