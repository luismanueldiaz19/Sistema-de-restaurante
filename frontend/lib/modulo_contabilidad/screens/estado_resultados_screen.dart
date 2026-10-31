import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../palletes/app_colors.dart';
import '../../utils/formatter_number.dart';
import '../../widgets/custom_empty_state.dart';
import '../providers/reportes_contables_provider.dart';
import '../widgets/contabilidad_shared_widgets.dart';
import '../widgets/contabilidad_tree_section_card.dart';
import 'estado_resultados_tabla_screen.dart';

class EstadoResultadosScreen extends ConsumerStatefulWidget {
  const EstadoResultadosScreen({super.key});

  @override
  ConsumerState<EstadoResultadosScreen> createState() =>
      _EstadoResultadosScreenState();
}

class _EstadoResultadosScreenState
    extends ConsumerState<EstadoResultadosScreen> {
  DateTime _fechaDesde = DateTime(DateTime.now().year, 1, 1);
  DateTime _fechaHasta = DateTime.now();

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

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');
    final paramStr = '${fmt.format(_fechaDesde)}|${fmt.format(_fechaHasta)}';
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
    final margenNeto = totalIngresos > 0
        ? ((utilidadNeta / totalIngresos) * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        title: const Text(
          'Estado de Resultados',
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
              MaterialPageRoute(
                builder: (_) => const EstadoResultadosTablaScreen(),
              ),
            ),
            icon: const Icon(Icons.table_chart_outlined, size: 15),
            label: const Text(
              'Vista Hoja (Excel)',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Actualizar Estado de Resultados',
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
                    label: 'Ingresos Operativos',
                    value: FormatterNumber.formatCurrency(totalIngresos),
                    icon: Icons.trending_up_rounded,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Costo de Ventas',
                    value: FormatterNumber.formatCurrency(totalCostos),
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Utilidad Bruta',
                    value: FormatterNumber.formatCurrency(utilidadBruta),
                    icon: Icons.analytics_outlined,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: utilidadNeta >= 0
                        ? 'Utilidad Neta'
                        : 'Pérdida Neta',
                    value: FormatterNumber.formatCurrency(utilidadNeta),
                    badge: '$margenNeto%',
                    icon: utilidadNeta >= 0
                        ? Icons.auto_graph_rounded
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
                  Icon(
                    Icons.date_range_rounded,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Período consultado:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                  const Spacer(),
                  ContabilidadQuickPresetChip(
                    label: 'Este Mes',
                    onTap: () => _setPeriodo('mes'),
                  ),
                  const SizedBox(width: 6),
                  ContabilidadQuickPresetChip(
                    label: 'Este Año',
                    onTap: () => _setPeriodo('anio'),
                  ),
                  const SizedBox(width: 6),
                  ContabilidadQuickPresetChip(
                    label: 'Todo',
                    onTap: () => _setPeriodo('todo'),
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
                  title: 'Error al consultar el Estado de Resultados',
                  subtitle: '$err',
                  icon: Icons.error_outline_rounded,
                ),
                data: (data) {
                  final ingresos =
                      (data['ingresos'] as List<dynamic>?) ?? const [];
                  final costos =
                      (data['costos'] as List<dynamic>?) ?? const [];
                  final gastos =
                      (data['gastos'] as List<dynamic>?) ?? const [];

                  return ListView(
                    children: [
                      ContabilidadTreeSectionCard(
                        title: '1. INGRESOS OPERATIVOS',
                        icon: Icons.payments_outlined,
                        accentColor: Colors.green.shade800,
                        nodos: ingresos,
                        total: totalIngresos,
                      ),
                      ContabilidadTreeSectionCard(
                        title: '2. COSTO DE VENTAS',
                        icon: Icons.shopping_bag_outlined,
                        accentColor: AppColors.primaryDark,
                        nodos: costos,
                        total: totalCostos,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ContabilidadSummaryBar(
                          title: 'UTILIDAD BRUTA (Ingresos - Costos)',
                          amount: utilidadBruta,
                          backgroundColor: const Color(0xFFE2E8F0),
                          foregroundColor: AppColors.azulOscuro,
                        ),
                      ),
                      ContabilidadTreeSectionCard(
                        title: '3. GASTOS OPERATIVOS Y ADMINISTRATIVOS',
                        icon: Icons.account_balance_wallet_outlined,
                        accentColor: Colors.indigo.shade800,
                        nodos: gastos,
                        total: totalGastos,
                      ),
                      ContabilidadSummaryBar(
                        title: utilidadNeta >= 0
                            ? 'UTILIDAD NETA DEL EJERCICIO'
                            : 'PÉRDIDA NETA DEL EJERCICIO',
                        subtitle:
                            'Margen neto sobre ventas: $margenNeto%',
                        amount: utilidadNeta,
                        backgroundColor: utilidadNeta >= 0
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ],
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
