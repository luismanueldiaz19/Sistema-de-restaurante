import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../providers/cxc_provider.dart';
import '../models/cxc.dart';
import '../../utils/helpers.dart';
import 'widgets/cxc_detalle_cobro_panel.dart';
import 'historial_pagos_cxc_screen.dart';

class CxcListScreen extends ConsumerStatefulWidget {
  const CxcListScreen({super.key});

  @override
  ConsumerState<CxcListScreen> createState() => _CxcListScreenState();
}

class _CxcListScreenState extends ConsumerState<CxcListScreen> {
  CuentaPorCobrar? _selectedCxc;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtroEstado = 'todas'; // 'todas', 'al_dia', 'vencidas'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cxcProvider.notifier).loadCxcs();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CuentaPorCobrar> _filtrarCxcs(List<CuentaPorCobrar> cxcs) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final now = DateTime.now();

    return cxcs.where((c) {
      // Solo con balance pendiente
      if (c.balancePendiente <= 0) return false;

      // Filtro de texto
      if (query.isNotEmpty) {
        final clienteNombre = (c.cliente?['nombre'] ?? '').toString().toLowerCase();
        final ncf = (c.factura?['ncf'] ?? '').toString().toLowerCase();
        final numFactura = (c.factura?['numero'] ?? '').toString().toLowerCase();
        final match = clienteNombre.contains(query) || ncf.contains(query) || numFactura.contains(query);
        if (!match) return false;
      }

      // Filtro de vencimiento
      final isVencida = c.fechaVencimiento != null && c.fechaVencimiento!.isBefore(now);
      if (_filtroEstado == 'vencidas' && !isVencida) return false;
      if (_filtroEstado == 'al_dia' && isVencida) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cxcProvider);

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
              'Cuentas por Cobrar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Gestión de cobros y facturas a crédito de clientes',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Botón Historial de Recibos
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
                        builder: (_) => const HistorialPagosCxcScreen(),
                      ),
                    );
                    if (context.mounted) {
                      ref.read(cxcProvider.notifier).loadCxcs();
                    }
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text(
                    'Historial de Recibos',
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
          // Botón Recargar
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Actualizar cuentas',
            onPressed: () {
              ref.read(cxcProvider.notifier).loadCxcs();
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
                          'Error al cargar Cuentas por Cobrar',
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
                          onPressed: () => ref.read(cxcProvider.notifier).loadCxcs(),
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
              : _buildDashboard(state.cxcs),
    );
  }

  Widget _buildDashboard(List<CuentaPorCobrar> cxcs) {
    final pendientes = cxcs.where((c) => c.balancePendiente > 0).toList();
    final now = DateTime.now();
    final vencidas = pendientes.where((c) => c.fechaVencimiento != null && c.fechaVencimiento!.isBefore(now)).toList();
    final alDia = pendientes.where((c) => c.fechaVencimiento == null || !c.fechaVencimiento!.isBefore(now)).toList();

    final totalCobrar = pendientes.fold(0.0, (sum, c) => sum + c.balancePendiente);
    final listaFiltrada = _filtrarCxcs(cxcs);

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
                      totalCobrar: totalCobrar,
                      totalFacturas: pendientes.length,
                      vencidasCount: vencidas.length,
                    ),

                    const SizedBox(height: 12),

                    // 2. Buscador y Filtros
                    _buildSearchBar(
                      totalCount: pendientes.length,
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
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final cxc = listaFiltrada[index];
                                final isSelected = _selectedCxc?.id == cxc.id;

                                return _buildCxcItemCard(
                                  cxc: cxc,
                                  isSelected: isSelected,
                                  isDesktop: isDesktop,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // PANEL DERECHO (Detalle y Formulario de Cobro en Escritorio)
              if (isDesktop) ...[
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: CxcDetalleCobroPanel(
                    cxc: _selectedCxc,
                    onCobroCompletado: () {
                      ref.read(cxcProvider.notifier).loadCxcs();
                      setState(() {
                        _selectedCxc = null;
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
    required double totalCobrar,
    required int totalFacturas,
    required int vencidasCount,
  }) {
    return Row(
      children: [
        // Total por Cobrar
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
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF059669),
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
                        'TOTAL POR COBRAR',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        FormatterNumber.formatCurrency(totalCobrar),
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669),
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
      child: Row(
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
                  hintText: 'Buscar cliente, NCF o factura...',
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

          // Filtro chips
          _buildFilterChip('Todas ($totalCount)', 'todas'),
          const SizedBox(width: 6),
          _buildFilterChip('Al Día ($alDiaCount)', 'al_dia'),
          const SizedBox(width: 6),
          _buildFilterChip('Vencidas ($vencidasCount)', 'vencidas', isDanger: vencidasCount > 0),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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

  // --- Card de Cada Factura en CxC ---
  Widget _buildCxcItemCard({
    required CuentaPorCobrar cxc,
    required bool isSelected,
    required bool isDesktop,
  }) {
    final now = DateTime.now();
    final fechaVenc = cxc.fechaVencimiento;
    final isVencida = fechaVenc != null && fechaVenc.isBefore(now);
    final diasDiferencia = fechaVenc != null ? fechaVenc.difference(now).inDays : 0;

    String vencimientoText;
    if (fechaVenc == null) {
      vencimientoText = 'Sin fecha';
    } else if (isVencida) {
      final diasVenc = diasDiferencia.abs();
      vencimientoText = diasVenc == 0 ? 'Vence hoy' : 'Vencida hace $diasVenc d';
    } else {
      vencimientoText = diasDiferencia == 0 ? 'Vence hoy' : 'Vence en $diasDiferencia d';
    }

    final clienteNombre = cxc.cliente?['nombre'] ?? 'Cliente General';
    final ncf = cxc.factura?['ncf'] ?? 'N/A';
    final numFactura = cxc.factura?['numero'] ?? '';

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCxc = cxc;
        });

        // En pantallas pequeñas / móviles abrir en BottomSheet
        if (!isDesktop) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top + 20),
              child: CxcDetalleCobroPanel(
                cxc: cxc,
                onCobroCompletado: () {
                  Navigator.pop(ctx);
                  ref.read(cxcProvider.notifier).loadCxcs();
                  setState(() {
                    _selectedCxc = null;
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
                : (isVencida ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
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
            // Cabecera: Cliente & Estado
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
                        : (isVencida
                            ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                            : const Color(0xFF059669).withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: isSelected
                        ? AppColors.azulOscuro
                        : (isVencida ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clienteNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
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
                              'NCF: $ncf',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          if (numFactura.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '#$numFactura',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
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
                    color: isVencida
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isVencida
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Text(
                    isVencida ? 'VENCIDA' : 'PENDIENTE',
                    style: TextStyle(
                      color: isVencida ? const Color(0xFFDC2626) : const Color(0xFF059669),
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
                          color: isVencida ? const Color(0xFFDC2626) : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fechaVenc != null
                              ? '${fechaVenc.year}-${fechaVenc.month.toString().padLeft(2, '0')}-${fechaVenc.day.toString().padLeft(2, '0')}'
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isVencida ? const Color(0xFFDC2626) : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: isVencida
                                ? const Color(0xFFDC2626).withValues(alpha: 0.08)
                                : const Color(0xFF059669).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            vencimientoText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isVencida ? const Color(0xFFDC2626) : const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Balance Pendiente
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'BALANCE PENDIENTE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      FormatterNumber.formatCurrency(cxc.balancePendiente),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF059669),
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
                  ? 'No hay facturas a crédito pendientes de cobro.'
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
