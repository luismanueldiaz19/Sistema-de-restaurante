import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../providers/cxp_provider.dart';
import '../models/cxp.dart';
import '../../utils/helpers.dart';
import 'widgets/cxp_detalle_pago_panel.dart';
import 'historial_pagos_cxp_screen.dart';
import '../../widgets/custom_date_range_picker.dart';

class CxpListScreen extends ConsumerStatefulWidget {
  const CxpListScreen({super.key});

  @override
  ConsumerState<CxpListScreen> createState() => _CxpListScreenState();
}

class _CxpListScreenState extends ConsumerState<CxpListScreen> {
  CuentaPorPagar? _selectedCxp;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtroEstado = 'pendientes'; // 'todas', 'pendientes', 'al_dia', 'vencidas', 'pagadas'
  String _selectedDateFilter = 'Todos';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cxpProvider.notifier).loadCxps();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CuentaPorPagar> _filtrarCxps(List<CuentaPorPagar> cxps) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final now = DateTime.now();

    return cxps.where((c) {
      final isVencida = c.fechaVencimiento.isBefore(now);

      // Filtro de Estado
      if (_filtroEstado == 'pendientes' && c.balancePendiente <= 0) return false;
      if (_filtroEstado == 'pagadas' && c.balancePendiente > 0) return false;
      if (_filtroEstado == 'al_dia' && (c.balancePendiente <= 0 || isVencida)) return false;
      if (_filtroEstado == 'vencidas' && (c.balancePendiente <= 0 || !isVencida)) return false;

      // Filtro de Fecha
      final fecha = c.fechaVencimiento;
      if (_selectedDateFilter == 'Hoy') {
        if (fecha.year != now.year || fecha.month != now.month || fecha.day != now.day) {
          return false;
        }
      } else if (_selectedDateFilter == 'Últimos 7 días') {
        if (fecha.isBefore(now.subtract(const Duration(days: 7)))) return false;
      } else if (_selectedDateFilter == 'Últimos 30 días') {
        if (fecha.isBefore(now.subtract(const Duration(days: 30)))) return false;
      } else if (_selectedDateFilter == 'Este mes') {
        if (fecha.year != now.year || fecha.month != now.month) return false;
      } else if (_selectedDateFilter == 'Mes pasado') {
        final mesPasado = DateTime(now.year, now.month - 1);
        if (fecha.year != mesPasado.year || fecha.month != mesPasado.month) return false;
      } else if (_selectedDateFilter == 'Este año') {
        if (fecha.year != now.year) return false;
      } else if (_selectedDateFilter == 'Personalizado' && _selectedDateRange != null) {
        if (fecha.isBefore(_selectedDateRange!.start) ||
            fecha.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Filtro de Búsqueda
      if (query.isNotEmpty) {
        final prov = (c.proveedor?.nombre ?? '').toLowerCase();
        final fact = (c.compra?.numeroFacturaProveedor ?? '').toLowerCase();
        final ncf = (c.compra?.ncf ?? '').toLowerCase();
        if (!prov.contains(query) && !fact.contains(query) && !ncf.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cxpProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuentas por Pagar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Gestión de pagos y obligaciones con proveedores',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Botón Historial de Pagos
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: SizedBox(
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistorialPagosCxpScreen(),
                      ),
                    );
                    if (context.mounted) {
                      ref.read(cxpProvider.notifier).loadCxps();
                    }
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text(
                    'Historial de Pagos',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ),
          // Botón Refrescar
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Actualizar cuentas',
            onPressed: () {
              ref.read(cxpProvider.notifier).loadCxps();
              setState(() {
                _selectedCxp = null;
              });
            },
            splashRadius: 18,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.azulOscuro,
                strokeWidth: 2.5,
              ),
            )
          : (state.error != null && state.error!.isNotEmpty)
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 36),
                        const SizedBox(height: 10),
                        const Text(
                          'Error al cargar Cuentas por Pagar',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(cxpProvider.notifier).loadCxps(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulOscuro,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildDashboard(state.cxps),
    );
  }

  Widget _buildDashboard(List<CuentaPorPagar> cxps) {
    final now = DateTime.now();
    final pendientes = cxps.where((c) => c.balancePendiente > 0).toList();
    final vencidas = pendientes.where((c) => c.fechaVencimiento.isBefore(now)).toList();
    final alDia = pendientes.where((c) => !c.fechaVencimiento.isBefore(now)).toList();

    final totalDeuda = pendientes.fold(0.0, (sum, c) => sum + c.balancePendiente);
    final listaFiltrada = _filtrarCxps(cxps);

    // Ordenar: primero las que tienen balance y luego por fecha de vencimiento
    listaFiltrada.sort((a, b) {
      if (a.balancePendiente > 0 && b.balancePendiente <= 0) return -1;
      if (a.balancePendiente <= 0 && b.balancePendiente > 0) return 1;
      return a.fechaVencimiento.compareTo(b.fechaVencimiento);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 850;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PANEL IZQUIERDO (Lista de Facturas & Métricas)
              Expanded(
                flex: isDesktop ? 6 : 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. KPI Cards Compactas
                    _buildKpiMetrics(
                      totalDeuda: totalDeuda,
                      totalFacturas: pendientes.length,
                      vencidasCount: vencidas.length,
                    ),

                    const SizedBox(height: 12),

                    // 2. Buscador y Filtros
                    _buildSearchBar(
                      totalCount: cxps.length,
                      pendientesCount: pendientes.length,
                      alDiaCount: alDia.length,
                      vencidasCount: vencidas.length,
                    ),

                    const SizedBox(height: 12),

                    // 3. Listado de Facturas
                    Expanded(
                      child: listaFiltrada.isEmpty
                          ? _buildEmptyState(pendientes.isEmpty)
                          : ListView.separated(
                              itemCount: listaFiltrada.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final cxp = listaFiltrada[index];
                                final isSelected = _selectedCxp?.id == cxp.id;

                                return _buildCxpItemCard(
                                  cxp: cxp,
                                  isSelected: isSelected,
                                  isDesktop: isDesktop,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // PANEL DERECHO (Detalle y Formulario de Pago en Escritorio)
              if (isDesktop) ...[
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: CxpDetalleYPagoPanel(
                    cxp: _selectedCxp,
                    onPagoCompletado: () {
                      ref.read(cxpProvider.notifier).loadCxps();
                      setState(() {
                        _selectedCxp = null;
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- KPI Cards ---
  Widget _buildKpiMetrics({
    required double totalDeuda,
    required int totalFacturas,
    required int vencidasCount,
  }) {
    return Row(
      children: [
        // Total por Pagar
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFFD97706),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TOTAL POR PAGAR',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        FormatterNumber.formatCurrency(totalDeuda),
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD97706),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Facturas Pendientes
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.azulOscuro.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.receipt_outlined, color: AppColors.azulOscuro, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PENDIENTES',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        '$totalFacturas fact.',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Vencidas
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: vencidasCount > 0 ? const Color(0xFFFEF2F2) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: vencidasCount > 0 ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: vencidasCount > 0
                        ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                        : const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    vencidasCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: vencidasCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VENCIDAS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: vencidasCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        '$vencidasCount fact.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: vencidasCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Buscador y Filtros ---
  Widget _buildSearchBar({
    required int totalCount,
    required int pendientesCount,
    required int alDiaCount,
    required int vencidasCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Input de búsqueda
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 11.5),
                    decoration: InputDecoration(
                      hintText: 'Buscar proveedor, factura o NCF...',
                      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, size: 15, color: Color(0xFF64748B)),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 13),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                        borderSide: BorderSide(color: AppColors.azulOscuro, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Selector de Fecha Rápido
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDateFilter,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todas las fechas')),
                      DropdownMenuItem(value: 'Hoy', child: Text('Hoy')),
                      DropdownMenuItem(value: 'Últimos 7 días', child: Text('Últimos 7 días')),
                      DropdownMenuItem(value: 'Este mes', child: Text('Este mes')),
                      DropdownMenuItem(value: 'Mes pasado', child: Text('Mes pasado')),
                      DropdownMenuItem(value: 'Personalizado', child: Text('Personalizado')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDateFilter = val;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 6),
              CustomDateRangePicker(
                isPersonalizado: _selectedDateFilter == 'Personalizado',
                onDateRangeSelected: (start, end) {
                  setState(() {
                    _selectedDateFilter = 'Personalizado';
                    _selectedDateRange = DateTimeRange(start: start, end: end);
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Chips de filtro de estado
          Row(
            children: [
              _buildFilterChip('Pendientes ($pendientesCount)', 'pendientes'),
              const SizedBox(width: 6),
              _buildFilterChip('Al Día ($alDiaCount)', 'al_dia'),
              const SizedBox(width: 6),
              _buildFilterChip('Vencidas ($vencidasCount)', 'vencidas', isDanger: vencidasCount > 0),
              const SizedBox(width: 6),
              _buildFilterChip('Todas ($totalCount)', 'todas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {bool isDanger = false}) {
    final isSelected = _filtroEstado == value;

    return InkWell(
      onTap: () => setState(() => _filtroEstado = value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDanger ? const Color(0xFFDC2626) : AppColors.azulOscuro)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (isDanger ? const Color(0xFFDC2626) : AppColors.azulOscuro)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // --- Card de Cada Factura en CxP ---
  Widget _buildCxpItemCard({
    required CuentaPorPagar cxp,
    required bool isSelected,
    required bool isDesktop,
  }) {
    final now = DateTime.now();
    final fechaVenc = cxp.fechaVencimiento;
    final isVencida = fechaVenc.isBefore(now);
    final diasDiferencia = fechaVenc.difference(now).inDays;

    String vencimientoText;
    if (isVencida) {
      final diasVenc = diasDiferencia.abs();
      vencimientoText = diasVenc == 0 ? 'Vence hoy' : 'Vencida hace $diasVenc d';
    } else {
      vencimientoText = diasDiferencia == 0 ? 'Vence hoy' : 'Vence en $diasDiferencia d';
    }

    final proveedorNombre = cxp.proveedor?.nombre ?? 'Proveedor General';
    final numFactura = cxp.compra?.numeroFacturaProveedor ?? 'N/A';
    final ncf = cxp.compra?.ncf ?? '';
    final estaPagada = cxp.balancePendiente <= 0;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCxp = cxp;
        });

        // En pantallas pequeñas / móviles abrir en BottomSheet
        if (!isDesktop) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top + 20),
              child: CxpDetalleYPagoPanel(
                cxp: cxp,
                onPagoCompletado: () {
                  Navigator.pop(ctx);
                  ref.read(cxpProvider.notifier).loadCxps();
                  setState(() {
                    _selectedCxp = null;
                  });
                },
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.azulOscuro.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.azulOscuro
                : (isVencida && !estaPagada ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Proveedor & Estado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.azulOscuro.withValues(alpha: 0.1)
                        : (estaPagada
                            ? const Color(0xFF059669).withValues(alpha: 0.1)
                            : (isVencida
                                ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                                : const Color(0xFFD97706).withValues(alpha: 0.1))),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.store_mall_directory_rounded,
                    color: isSelected
                        ? AppColors.azulOscuro
                        : (estaPagada
                            ? const Color(0xFF059669)
                            : (isVencida ? const Color(0xFFDC2626) : const Color(0xFFD97706))),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proveedorNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Fac: $numFactura',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          if (ncf.isNotEmpty && ncf != 'N/A') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                'NCF: $ncf',
                                style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge de estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: estaPagada
                        ? const Color(0xFFECFDF5)
                        : (isVencida ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: estaPagada
                          ? const Color(0xFFA7F3D0)
                          : (isVencida ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A)),
                    ),
                  ),
                  child: Text(
                    estaPagada ? 'PAGADA' : (isVencida ? 'VENCIDA' : 'AL DÍA'),
                    style: TextStyle(
                      color: estaPagada
                          ? const Color(0xFF059669)
                          : (isVencida ? const Color(0xFFDC2626) : const Color(0xFFB45309)),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),

            // Pie: Vencimiento y Montos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Vencimiento
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FECHA LÍMITE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: isVencida && !estaPagada ? const Color(0xFFDC2626) : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${fechaVenc.year}-${fechaVenc.month.toString().padLeft(2, '0')}-${fechaVenc.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isVencida && !estaPagada ? const Color(0xFFDC2626) : const Color(0xFF334155),
                          ),
                        ),
                        if (!estaPagada) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isVencida
                                  ? const Color(0xFFDC2626).withValues(alpha: 0.08)
                                  : const Color(0xFFD97706).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              vencimientoText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isVencida ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Balance Pendiente
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      estaPagada ? 'SALDADA' : 'BALANCE PENDIENTE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      FormatterNumber.formatCurrency(cxp.balancePendiente),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: estaPagada ? const Color(0xFF059669) : const Color(0xFFD97706),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool todoAlDia) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: todoAlDia
                    ? const Color(0xFF059669).withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                todoAlDia ? Icons.check_circle_outline_rounded : Icons.search_off_rounded,
                color: todoAlDia ? const Color(0xFF059669) : const Color(0xFF64748B),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              todoAlDia ? '¡Cuentas al Día!' : 'No se encontraron facturas',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              todoAlDia
                  ? 'No hay facturas a crédito pendientes de pago a proveedores.'
                  : 'Ninguna cuenta coincide con los filtros aplicados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
