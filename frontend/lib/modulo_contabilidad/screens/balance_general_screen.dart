import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../palletes/app_colors.dart';
import '../../utils/formatter_number.dart';
import '../../widgets/custom_empty_state.dart';
import '../providers/reportes_contables_provider.dart';
import '../widgets/contabilidad_shared_widgets.dart';
import '../widgets/contabilidad_tree_section_card.dart';

class BalanceGeneralScreen extends ConsumerStatefulWidget {
  const BalanceGeneralScreen({super.key});

  @override
  ConsumerState<BalanceGeneralScreen> createState() =>
      _BalanceGeneralScreenState();
}

class _BalanceGeneralScreenState extends ConsumerState<BalanceGeneralScreen> {
  DateTime _fechaHasta = DateTime.now();

  Future<void> _seleccionarFecha() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaHasta,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _fechaHasta = date);
    }
  }

  Widget _buildUtilidadRow(double utilidad) {
    final positive = utilidad >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
      decoration: BoxDecoration(
        color: (positive ? Colors.green : Colors.red).withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(
            positive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 14,
            color: positive ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              positive
                  ? 'Utilidad Acumulada del Ejercicio'
                  : 'Pérdida Acumulada del Ejercicio',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.azulOscuro,
              ),
            ),
          ),
          Text(
            FormatterNumber.formatCurrency(utilidad),
            style: TextStyle(
              fontSize: 11.5,
              fontFamily: 'Consolas',
              fontWeight: FontWeight.w800,
              color: positive ? Colors.green.shade800 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fHasta = DateFormat('yyyy-MM-dd').format(_fechaHasta);
    final asyncData = ref.watch(balanceGeneralProvider(fHasta));

    final map = asyncData.asData?.value;
    final totales = (map?['totales'] as Map<String, dynamic>?) ?? const {};
    final totalActivo = FormatterNumber.parseDouble(totales['activo']);
    final totalPasivo = FormatterNumber.parseDouble(totales['pasivo']);
    final totalCapital = FormatterNumber.parseDouble(totales['capital']);
    final utilidad = FormatterNumber.parseDouble(map?['utilidad_ejercicio']);
    final capitalConUtilidad = totalCapital + utilidad;
    final pasivoYCapital = FormatterNumber.parseDouble(
      totales['pasivo_y_capital'],
    );
    final diff = (totalActivo - pasivoYCapital).abs();
    final isBalanced = diff <= 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        title: const Text(
          'Balance General',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
        actions: [
          Center(
            child: ContabilidadDateButton(
              prefix: 'Corte al',
              date: _fechaHasta,
              onTap: _seleccionarFecha,
            ),
          ),
          const SizedBox(width: 6),
          Center(
            child: ContabilidadQuickPresetChip(
              label: 'Hoy',
              onTap: () => setState(() => _fechaHasta = DateTime.now()),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Actualizar Balance General',
            icon: const Icon(Icons.refresh_rounded, size: 19),
            onPressed: () => ref.invalidate(balanceGeneralProvider(fHasta)),
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
                    label: 'Total Activos',
                    value: FormatterNumber.formatCurrency(totalActivo),
                    icon: Icons.account_balance_rounded,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Total Pasivos',
                    value: FormatterNumber.formatCurrency(totalPasivo),
                    icon: Icons.receipt_long_outlined,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Capital + Resultado',
                    value: FormatterNumber.formatCurrency(capitalConUtilidad),
                    icon: Icons.pie_chart_outline_rounded,
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Ecuación (A = P + C)',
                    value: isBalanced
                        ? 'Cuadrado'
                        : 'Dif: ${FormatterNumber.formatCurrency(diff)}',
                    icon: isBalanced
                        ? Icons.verified_outlined
                        : Icons.warning_amber_rounded,
                    color: isBalanced
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: asyncData.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => CustomEmptyState(
                  title: 'Error al consultar el Balance General',
                  subtitle: '$err',
                  icon: Icons.error_outline_rounded,
                ),
                data: (data) {
                  final activos =
                      (data['activos'] as List<dynamic>?) ?? const [];
                  final pasivos =
                      (data['pasivos'] as List<dynamic>?) ?? const [];
                  final capital =
                      (data['capital'] as List<dynamic>?) ?? const [];

                  final leftColumn = Column(
                    children: [
                      ContabilidadTreeSectionCard(
                        title: '1. ACTIVOS',
                        icon: Icons.account_balance_wallet_outlined,
                        accentColor: Colors.blue.shade800,
                        nodos: activos,
                        total: totalActivo,
                      ),
                      ContabilidadSummaryBar(
                        title: 'TOTAL ACTIVOS',
                        subtitle:
                            'Recursos y derechos al ${FormatterNumber.formatFechaLatina(_fechaHasta)}',
                        amount: totalActivo,
                        backgroundColor: Colors.blue.shade900,
                      ),
                    ],
                  );

                  final rightColumn = Column(
                    children: [
                      ContabilidadTreeSectionCard(
                        title: '2. PASIVOS',
                        icon: Icons.assignment_late_outlined,
                        accentColor: Colors.orange.shade800,
                        nodos: pasivos,
                        total: totalPasivo,
                      ),
                      ContabilidadTreeSectionCard(
                        title: '3. CAPITAL PATRIMONIAL',
                        icon: Icons.shield_outlined,
                        accentColor: Colors.purple.shade700,
                        nodos: capital,
                        total: capitalConUtilidad,
                        extraBottomRows: [_buildUtilidadRow(utilidad)],
                      ),
                      ContabilidadSummaryBar(
                        title: 'TOTAL PASIVO Y CAPITAL',
                        subtitle: 'Obligaciones + Patrimonio neto + Resultado',
                        amount: pasivoYCapital,
                        backgroundColor: AppColors.azulOscuro,
                      ),
                    ],
                  );

                  return LayoutBuilder(
                    builder: (_, constraints) {
                      final wide = constraints.maxWidth >= 920;
                      return SingleChildScrollView(
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: leftColumn),
                                  const SizedBox(width: 10),
                                  Expanded(child: rightColumn),
                                ],
                              )
                            : Column(
                                children: [
                                  leftColumn,
                                  const SizedBox(height: 10),
                                  rightColumn,
                                ],
                              ),
                      );
                    },
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
