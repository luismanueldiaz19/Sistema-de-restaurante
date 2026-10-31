import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../palletes/app_colors.dart';
import '../../utils/formatter_number.dart';
import '../../widgets/custom_empty_state.dart';
import '../../widgets/custom_filter_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../providers/reportes_contables_provider.dart';
import '../widgets/contabilidad_shared_widgets.dart';

class MayorGeneralScreen extends ConsumerStatefulWidget {
  const MayorGeneralScreen({super.key});

  @override
  ConsumerState<MayorGeneralScreen> createState() => _MayorGeneralScreenState();
}

class _MayorGeneralScreenState extends ConsumerState<MayorGeneralScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime _fechaDesde = DateTime(DateTime.now().year, 1, 1);
  DateTime _fechaHasta = DateTime.now();
  String _searchQuery = '';
  String _filtroTipo = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
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

  void _setPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      if (preset == 'mes') {
        _fechaDesde = DateTime(now.year, now.month, 1);
        _fechaHasta = now;
      } else {
        _fechaDesde = DateTime(now.year, 1, 1);
        _fechaHasta = now;
      }
    });
  }

  Color _tipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'activo':
        return Colors.blue.shade700;
      case 'pasivo':
        return Colors.orange.shade800;
      case 'capital':
        return Colors.purple.shade700;
      case 'ingresos':
        return Colors.green.shade700;
      case 'costos':
        return Colors.brown.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');
    final paramStr =
        '${fmt.format(_fechaDesde)}|${fmt.format(_fechaHasta)}';
    final asyncData = ref.watch(mayorGeneralProvider(paramStr));

    final rawList = asyncData.asData?.value ?? const [];
    final filtered = rawList.where((c) {
      final tipo = (c['tipo'] ?? '').toString();
      if (_filtroTipo.isNotEmpty &&
          tipo.toLowerCase() != _filtroTipo.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      return (c['nombre'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery) ||
          (c['codigo'] ?? '').toString().toLowerCase().contains(_searchQuery);
    }).toList();

    double sumDebito = 0;
    double sumCredito = 0;
    for (final c in filtered) {
      sumDebito += FormatterNumber.parseDouble(c['total_debito']);
      sumCredito += FormatterNumber.parseDouble(c['total_credito']);
    }
    final isBalanced = (sumDebito - sumCredito).abs() <= 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        title: const Text(
          'Mayor General',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Actualizar Mayor General',
            icon: const Icon(Icons.refresh_rounded, size: 19),
            onPressed: () => ref.invalidate(mayorGeneralProvider(paramStr)),
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
                    label: 'Cuentas con Movimiento',
                    value: '${filtered.length}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Total Débitos (DR)',
                    value: FormatterNumber.formatCurrency(sumDebito),
                    icon: Icons.north_east_rounded,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Total Créditos (CR)',
                    value: FormatterNumber.formatCurrency(sumCredito),
                    icon: Icons.south_west_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: _filtroTipo.isEmpty
                        ? 'Cuadre del Mayor'
                        : 'Diferencia (${_filtroTipo.toUpperCase()})',
                    value: _filtroTipo.isEmpty && isBalanced
                        ? 'Cuadrado'
                        : FormatterNumber.formatCurrency(
                            sumDebito - sumCredito,
                          ),
                    icon: isBalanced
                        ? Icons.verified_outlined
                        : Icons.tune_rounded,
                    color: isBalanced
                        ? Colors.green.shade700
                        : AppColors.azulOscuro,
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
                      controller: _searchCtrl,
                      label: '',
                      hintText: 'Buscar por código contable o nombre...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterDropdown<String>(
                    height: 36,
                    value: _filtroTipo,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Tipo: Todos')),
                      DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                      DropdownMenuItem(value: 'Pasivo', child: Text('Pasivo')),
                      DropdownMenuItem(
                        value: 'Capital',
                        child: Text('Capital'),
                      ),
                      DropdownMenuItem(
                        value: 'Ingresos',
                        child: Text('Ingresos'),
                      ),
                      DropdownMenuItem(value: 'Costos', child: Text('Costos')),
                      DropdownMenuItem(value: 'Gastos', child: Text('Gastos')),
                    ],
                    onChanged: (v) => setState(() => _filtroTipo = v ?? ''),
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
                    onTap: () => _setPreset('mes'),
                  ),
                  const SizedBox(width: 4),
                  ContabilidadQuickPresetChip(
                    label: 'Este Año',
                    onTap: () => _setPreset('anio'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 105,
                            child: ContabilidadTableHeaderText('Código'),
                          ),
                          Expanded(
                            flex: 4,
                            child: ContabilidadTableHeaderText(
                              'Cuenta Contable',
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: ContabilidadTableHeaderText('Tipo'),
                          ),
                          SizedBox(
                            width: 135,
                            child: ContabilidadTableHeaderText(
                              'Débitos (DR)',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 135,
                            child: ContabilidadTableHeaderText(
                              'Créditos (CR)',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 145,
                            child: ContabilidadTableHeaderText(
                              'Balance',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: asyncData.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => CustomEmptyState(
                          title: 'Error al consultar el Mayor General',
                          subtitle: '$err',
                          icon: Icons.error_outline_rounded,
                        ),
                        data: (_) {
                          if (filtered.isEmpty) {
                            return const CustomEmptyState(
                              title: 'Sin cuentas con movimientos en el rango',
                              icon: Icons.menu_book_outlined,
                            );
                          }
                          return ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (_, i) {
                              final c = filtered[i];
                              final codigo = (c['codigo'] ?? '').toString();
                              final nombre = (c['nombre'] ?? '').toString();
                              final tipo = (c['tipo'] ?? '').toString();
                              final deb = FormatterNumber.parseDouble(
                                c['total_debito'],
                              );
                              final cred = FormatterNumber.parseDouble(
                                c['total_credito'],
                              );
                              final bal = FormatterNumber.parseDouble(
                                c['balance'],
                              );
                              final tColor = _tipoColor(tipo);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 105,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            codigo,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontFamily: 'Consolas',
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.azulOscuro,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.azulOscuro,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            tipo,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: tColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 135,
                                      child: Text(
                                        FormatterNumber.formatCurrency(deb),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontFamily: 'Consolas',
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.azulOscuro,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 135,
                                      child: Text(
                                        FormatterNumber.formatCurrency(cred),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontFamily: 'Consolas',
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.azulOscuro,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 145,
                                      child: Text(
                                        FormatterNumber.formatCurrency(bal),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontFamily: 'Consolas',
                                          fontWeight: FontWeight.w800,
                                          color: bal < 0
                                              ? Colors.red.shade700
                                              : Colors.green.shade800,
                                        ),
                                      ),
                                    ),
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
            ),
          ],
        ),
      ),
    );
  }
}
