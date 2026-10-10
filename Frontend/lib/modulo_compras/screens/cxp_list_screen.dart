import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../providers/cxp_provider.dart';
import '../models/cxp.dart';
import '../../utils/helpers.dart';
import 'widgets/cxp_detalle_pago_panel.dart';
import '../../widgets/custom_date_range_picker.dart';
import '../../widgets/custom_filter_dropdown.dart';

class CxpListScreen extends ConsumerStatefulWidget {
  const CxpListScreen({super.key});

  @override
  ConsumerState<CxpListScreen> createState() => _CxpListScreenState();
}

class _CxpListScreenState extends ConsumerState<CxpListScreen> {
  CuentaPorPagar? _selectedCxp;
  String _searchQuery = '';
  String _selectedDateFilter = 'Todos';
  String _selectedEstadoFilter = 'pendientes';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cxpProvider.notifier).loadCxps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cxpProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuentas por Pagar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
              ),
            ),
            Text(
              'Gestión de pagos y obligaciones',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.secondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              ref.read(cxpProvider.notifier).loadCxps();
              setState(() {
                _selectedCxp = null;
              });
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : (state.error != null && state.error!.isNotEmpty)
          ? Center(
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          : _buildDashboard(state.cxps),
    );
  }

  Widget _buildDashboard(List<CuentaPorPagar> cxps) {
    // 1. Filtrar
    var filtrados = cxps.where((c) {
      // Estado
      if (_selectedEstadoFilter == 'pendientes' && c.balancePendiente <= 0) {
        return false;
      }
      if (_selectedEstadoFilter == 'pagadas' && c.balancePendiente > 0) {
        return false;
      }

      // Fecha
      final fecha = c.fechaVencimiento;
      final now = DateTime.now();
      if (_selectedDateFilter == 'Hoy') {
        if (fecha.year != now.year ||
            fecha.month != now.month ||
            fecha.day != now.day) {
          return false;
        }
      } else if (_selectedDateFilter == 'Últimos 7 días') {
        if (fecha.isBefore(now.subtract(const Duration(days: 7)))) return false;
      } else if (_selectedDateFilter == 'Últimos 30 días') {
        if (fecha.isBefore(now.subtract(const Duration(days: 30)))) {
          return false;
        }
      } else if (_selectedDateFilter == 'Este mes') {
        if (fecha.year != now.year || fecha.month != now.month) return false;
      } else if (_selectedDateFilter == 'Mes pasado') {
        final mesPasado = DateTime(now.year, now.month - 1);
        if (fecha.year != mesPasado.year || fecha.month != mesPasado.month) {
          return false;
        }
      } else if (_selectedDateFilter == 'Este año') {
        if (fecha.year != now.year) return false;
      } else if (_selectedDateFilter == 'Personalizado' &&
          _selectedDateRange != null) {
        if (fecha.isBefore(_selectedDateRange!.start) ||
            fecha.isAfter(
              _selectedDateRange!.end.add(const Duration(days: 1)),
            )) {
          return false;
        }
      }

      // Busqueda
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final prov = (c.proveedor?.nombre ?? '').toLowerCase();
        final fact = (c.compra?.numeroFacturaProveedor ?? '').toLowerCase();
        if (!prov.contains(q) && !fact.contains(q)) return false;
      }

      return true;
    }).toList();

    // Ordenar por fecha (más reciente)
    filtrados.sort((a, b) => b.fechaVencimiento.compareTo(a.fechaVencimiento));

    final totalDeuda = filtrados
        .where((c) => c.balancePendiente > 0)
        .fold(0.0, (sum, c) => sum + c.balancePendiente);

    if (filtrados.isEmpty &&
        _searchQuery.isEmpty &&
        _selectedDateFilter == 'Todos' &&
        _selectedEstadoFilter == 'pendientes') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green.shade200,
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Todo al día!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            Text(
              'No tienes cuentas por pagar pendientes.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 800;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PANEL IZQUIERDO (Lista)
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    // FILTROS
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Icon(
                                      Icons.search,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (val) {
                                        setState(() {
                                          _searchQuery = val;
                                        });
                                      },
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Buscar por proveedor o factura...',
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade400,
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 11,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CustomDateRangePicker(
                            isPersonalizado:
                                _selectedDateFilter == 'Personalizado',
                            onDateRangeSelected: (start, end) {
                              setState(() {
                                _selectedDateFilter = 'Personalizado';
                                _selectedDateRange = DateTimeRange(
                                  start: start,
                                  end: end,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          CustomFilterDropdown<String>(
                            value: _selectedDateFilter,
                            items:
                                [
                                      'Todos',
                                      'Hoy',
                                      'Últimos 7 días',
                                      'Últimos 30 días',
                                      'Este mes',
                                      'Mes pasado',
                                      'Este año',
                                      'Personalizado',
                                    ]
                                    .map(
                                      (f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null && val != 'Personalizado') {
                                setState(() {
                                  _selectedDateFilter = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          CustomFilterDropdown<String>(
                            value: _selectedEstadoFilter,
                            items: const [
                              DropdownMenuItem(
                                value: 'todos',
                                child: Text('Estado: Todos'),
                              ),
                              DropdownMenuItem(
                                value: 'pendientes',
                                child: Text('Pendientes'),
                              ),
                              DropdownMenuItem(
                                value: 'pagadas',
                                child: Text('Pagadas'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedEstadoFilter = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // HEADER TABLA
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Proveedor',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Factura',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Balance',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Estado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Vence',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // LISTA TABLA
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border(
                            left: BorderSide(color: Colors.grey.shade300),
                            right: BorderSide(color: Colors.grey.shade300),
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: ListView.separated(
                          itemCount: filtrados.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            final cxp = filtrados[index];
                            final isVencida = cxp.fechaVencimiento.isBefore(
                              DateTime.now(),
                            );
                            final isSelected = _selectedCxp?.id == cxp.id;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCxp = cxp;
                                });
                                if (!isTablet) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) => Padding(
                                      padding: EdgeInsets.only(
                                        top:
                                            MediaQuery.of(ctx).padding.top + 20,
                                      ),
                                      child: CxpDetalleYPagoPanel(
                                        cxp: cxp,
                                        onPagoCompletado: () {
                                          Navigator.pop(ctx);
                                          setState(() {
                                            _selectedCxp = null;
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.05)
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        cxp.proveedor?.nombre ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        cxp.compra?.numeroFacturaProveedor ??
                                            '-',
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        FormatterNumber.formatCurrency(cxp.balancePendiente),
                                        style: const TextStyle(
                                          color: AppColors.danger,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isVencida
                                                ? Colors.red.shade50
                                                : Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            isVencida ? 'VENCIDA' : 'AL DÍA',
                                            style: TextStyle(
                                              color: isVencida
                                                  ? Colors.red
                                                  : Colors.green,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cxp.fechaVencimiento
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0],
                                            style: TextStyle(
                                              color: isVencida
                                                  ? Colors.red
                                                  : Colors.black87,
                                              fontSize: 10,
                                            ),
                                          ),
                                          if (isVencida)
                                            Text(
                                              'Hace ${DateTime.now().difference(cxp.fechaVencimiento).inDays} días',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // TOTAL (Footer)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deuda Total Pendiente',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                FormatterNumber.formatCurrency(totalDeuda),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isTablet) const SizedBox(width: 24),

              // PANEL DERECHO (Detalle y Pago)
              if (isTablet)
                Expanded(
                  flex: 4,
                  child: CxpDetalleYPagoPanel(
                    cxp: _selectedCxp,
                    onPagoCompletado: () {
                      setState(() {
                        _selectedCxp = null;
                      });
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
