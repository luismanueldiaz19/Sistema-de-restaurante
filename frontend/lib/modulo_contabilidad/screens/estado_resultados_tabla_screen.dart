import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_empty_state.dart';
import '../../widgets/custom_text_field.dart';
import '../providers/reportes_contables_provider.dart';
import '../widgets/contabilidad_shared_widgets.dart';
import '../widgets/estado_resultados_hoja_table.dart';
import 'estado_resultados_screen.dart';

class EstadoResultadosTablaScreen extends ConsumerStatefulWidget {
  const EstadoResultadosTablaScreen({super.key});

  @override
  ConsumerState<EstadoResultadosTablaScreen> createState() =>
      _EstadoResultadosTablaScreenState();
}

class _EstadoResultadosTablaScreenState
    extends ConsumerState<EstadoResultadosTablaScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _fechaDesde = DateTime(DateTime.now().year, 1, 1);
  DateTime _fechaHasta = DateTime.now();
  bool _incluirCeros = true;
  String _filtroTexto = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(bool isDesde) async {
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
      } else {
        _fechaDesde = DateTime(2020, 1, 1);
        _fechaHasta = now;
      }
    });
  }

  List<Map<String, dynamic>> _extraerDetalle(List<dynamic> nodos) {
    final out = <Map<String, dynamic>>[];
    for (final raw in nodos) {
      final map = Map<String, dynamic>.from(raw as Map);
      final hijos = map['hijos'] as List<dynamic>?;
      if (map['es_detalle'] == true || hijos == null || hijos.isEmpty) {
        out.add(map);
      } else {
        out.addAll(_extraerDetalle(hijos));
      }
    }
    return out;
  }

  List<Map<String, dynamic>> _filtrar(List<Map<String, dynamic>> items) {
    if (_filtroTexto.isEmpty) return items;
    return items.where((c) {
      return (c['codigo'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_filtroTexto) ||
          (c['nombre'] ?? '').toString().toLowerCase().contains(_filtroTexto);
    }).toList();
  }

  Future<void> _copiarParaExcel(Map<String, dynamic>? data) async {
    if (data == null) return;
    final ing = _filtrar(_extraerDetalle(data['ingresos'] as List? ?? []));
    final cos = _filtrar(_extraerDetalle(data['costos'] as List? ?? []));
    final gas = _filtrar(_extraerDetalle(data['gastos'] as List? ?? []));
    final tot = (data['totales'] as Map<String, dynamic>?) ?? const {};

    final sb = StringBuffer()..writeln('CODIGO\tCUENTA\tRUBRO\tSALDO');
    void dump(List<Map<String, dynamic>> list, String rubro) {
      for (final r in list) {
        final bal = FormatterNumber.parseDouble(
          r['balance'],
        ).toStringAsFixed(2);
        sb.writeln('${r['codigo']}\t${r['nombre']}\t$rubro\t$bal');
      }
    }

    dump(ing, 'Ingresos');
    sb.writeln(
      '\tSubtotal Ingresos\t\t${FormatterNumber.parseDouble(tot['ingresos']).toStringAsFixed(2)}',
    );
    dump(cos, 'Costos');
    sb.writeln(
      '\tSubtotal Costos\t\t${FormatterNumber.parseDouble(tot['costos']).toStringAsFixed(2)}',
    );
    sb.writeln(
      '\tUTILIDAD BRUTA\t\t${FormatterNumber.parseDouble(tot['utilidad_bruta']).toStringAsFixed(2)}',
    );
    dump(gas, 'Gastos');
    sb.writeln(
      '\tSubtotal Gastos\t\t${FormatterNumber.parseDouble(tot['gastos']).toStringAsFixed(2)}',
    );
    sb.writeln(
      '\tRESULTADO NETO\t\t${FormatterNumber.parseDouble(tot['utilidad_neta']).toStringAsFixed(2)}',
    );

    await Clipboard.setData(ClipboardData(text: sb.toString()));
    if (!mounted) return;
    showToast(
      context,
      'Tabla copiada al portapapeles (lista para pegar en Excel)',
      bgColor: Colors.teal.shade700,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');
    final fDesde = fmt.format(_fechaDesde);
    final fHasta = fmt.format(_fechaHasta);
    final paramStr = "$fDesde|$fHasta|${_incluirCeros ? '1' : '0'}";
    final asyncData = ref.watch(estadoResultadosProvider(paramStr));

    final map = asyncData.asData?.value;
    final totales = (map?['totales'] as Map<String, dynamic>?) ?? const {};
    final totalIngresos = FormatterNumber.parseDouble(totales['ingresos']);
    final totalCostos = FormatterNumber.parseDouble(totales['costos']);
    final utilidadBruta = FormatterNumber.parseDouble(
      totales['utilidad_bruta'],
    );
    final totalGastos = FormatterNumber.parseDouble(totales['gastos']);
    final utilidadNeta = FormatterNumber.parseDouble(totales['utilidad_neta']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        title: const Text(
          'Estado de Resultados (Hoja Contable)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EstadoResultadosScreen()),
            ),
            icon: const Icon(Icons.view_agenda_outlined, size: 15),
            label: const Text(
              'Vista Resumen',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: map == null ? null : () => _copiarParaExcel(map),
            icon: const Icon(Icons.copy_all_rounded, size: 15),
            label: const Text(
              'Copiar a Excel',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulOscuro,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Actualizar hoja contable',
            icon: const Icon(Icons.refresh_rounded, size: 19),
            onPressed: () =>
                ref.invalidate(estadoResultadosProvider(paramStr)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Subtotal Ingresos',
                    value: FormatterNumber.formatCurrency(totalIngresos),
                    icon: Icons.trending_up_rounded,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Subtotal Costos',
                    value: FormatterNumber.formatCurrency(totalCostos),
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Subtotal Gastos',
                    value: FormatterNumber.formatCurrency(totalGastos),
                    icon: Icons.receipt_long_outlined,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: utilidadNeta >= 0
                        ? 'Utilidad Neta'
                        : 'Pérdida Neta',
                    value: FormatterNumber.formatCurrency(utilidadNeta),
                    icon: utilidadNeta >= 0
                        ? Icons.verified_outlined
                        : Icons.trending_down_rounded,
                    color: utilidadNeta >= 0
                        ? Colors.green.shade800
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _searchController,
                      label: '',
                      hintText: 'Filtrar cuenta por código o nombre...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (v) =>
                          setState(() => _filtroTexto = v.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ContabilidadDateButton(
                    prefix: 'Desde',
                    date: _fechaDesde,
                    onTap: () => _seleccionarFecha(true),
                  ),
                  const SizedBox(width: 6),
                  ContabilidadDateButton(
                    prefix: 'Hasta',
                    date: _fechaHasta,
                    onTap: () => _seleccionarFecha(false),
                  ),
                  const SizedBox(width: 6),
                  ContabilidadQuickPresetChip(
                    label: 'Este Mes',
                    onTap: () => _setPeriodo('mes'),
                  ),
                  const SizedBox(width: 4),
                  ContabilidadQuickPresetChip(
                    label: 'Este Año',
                    onTap: () => _setPeriodo('anio'),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _incluirCeros = !_incluirCeros),
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: _incluirCeros
                            ? AppColors.azulOscuro.withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: _incluirCeros
                              ? AppColors.azulOscuro.withValues(alpha: 0.3)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _incluirCeros
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 15,
                            color: _incluirCeros
                                ? AppColors.azulOscuro
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Incluir \$0',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.azulOscuro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: asyncData.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => CustomEmptyState(
                  title: 'Error al cargar hoja contable',
                  subtitle: '$err',
                  icon: Icons.error_outline_rounded,
                ),
                data: (data) {
                  final ing = _filtrar(
                    _extraerDetalle(data['ingresos'] as List? ?? []),
                  );
                  final cos = _filtrar(
                    _extraerDetalle(data['costos'] as List? ?? []),
                  );
                  final gas = _filtrar(
                    _extraerDetalle(data['gastos'] as List? ?? []),
                  );

                  return SingleChildScrollView(
                    child: EstadoResultadosHojaTable(
                      cuentasIngresos: ing,
                      cuentasCostos: cos,
                      cuentasGastos: gas,
                      totalIngresos: totalIngresos,
                      totalCostos: totalCostos,
                      utilidadBruta: utilidadBruta,
                      totalGastos: totalGastos,
                      utilidadNeta: utilidadNeta,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
