import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../providers/facturacion_historial_provider.dart';
import '../../model/factura.dart';

class HistorialVentasScreen extends ConsumerStatefulWidget {
  const HistorialVentasScreen({super.key});

  @override
  ConsumerState<HistorialVentasScreen> createState() =>
      _HistorialVentasScreenState();
}

class _HistorialVentasScreenState extends ConsumerState<HistorialVentasScreen> {
  final _fechaDesdeController = TextEditingController();
  final _fechaHastaController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(facturacionHistorialProvider.notifier).fetchHistorial(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(facturacionHistorialProvider);
    final auth = ref.watch(authProvider);
    final token = auth.token;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'HISTORIAL DE VENTAS',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.secondary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              if (token != null) {
                ref
                    .read(facturacionHistorialProvider.notifier)
                    .fetchHistorial(token);
              }
            },
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PANEL IZQUIERDO: Filtros y Totales (ULTRA-COMPACTO)
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTALES ACUMULADOS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildUltraCompactTotals(state),
                        const Divider(
                          height: 32,
                          thickness: 1,
                          color: Color(0xFFF0F0F0),
                        ),
                        const Text(
                          'BÚSQUEDA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSearchField(token),
                        const SizedBox(height: 20),
                        const Text(
                          'FILTROS RÁPIDOS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildQuickFilters(token),
                        const SizedBox(height: 20),
                        const Text(
                          'RANGO Y ESTADO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFilters(token, state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PANEL DERECHO: Tabla de Facturas y Paginación
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: state.isLoading && state.historial.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildTable(state.historial)),
                        _buildPagination(token, state),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltraCompactTotals(FacturacionHistorialState state) {
    final resumen = state.resumen;
    final totales = resumen?['totales'];
    final porMetodo = resumen?['por_metodo'] as List? ?? [];

    if (resumen == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _denseTotalRow('Facturas', '${totales?['cantidad_facturas'] ?? 0}'),
          _denseTotalRow(
            'Total Vendido',
            formatCurrency(
              double.parse((totales?['total_venta'] ?? 0).toString()),
            ),
            isPrimary: true,
          ),
          _denseTotalRow(
            'Total ITBIS',
            formatCurrency(
              double.parse((totales?['total_itbis'] ?? 0).toString()),
            ),
          ),
          _denseTotalRow(
            'Descuentos',
            formatCurrency(
              double.parse((totales?['total_descuento'] ?? 0).toString()),
            ),
          ),
          if (porMetodo.isNotEmpty) ...[
            const Divider(height: 16, thickness: 0.5),
            const Text(
              'MÉTODOS DE PAGO',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            ...porMetodo.map(
              (m) => _denseSubRow(
                (m['metodo_pago'] as String).toUpperCase(),
                formatCurrency(double.parse(m['total'].toString())),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _denseSubRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '• $label',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _denseTotalRow(String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isPrimary ? 14 : 13,
              fontWeight: FontWeight.w900,
              color: isPrimary ? AppColors.primary : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(String? token) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Nº Factura, Cliente o NCF',
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: (value) {
          if (token != null) {
            ref.read(facturacionHistorialProvider.notifier).updateFilters(
              token,
              {'search': value},
            );
          }
        },
      ),
    );
  }

  Widget _buildQuickFilters(String? token) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ['Hoy', 'Ayer', 'Este Mes', 'Este Año'].map((filtro) {
        return ActionChip(
          padding: const EdgeInsets.all(4),
          label: Text(
            filtro,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onPressed: () {
            if (token == null) return;
            final now = DateTime.now();
            String fechaDesde = '';
            String fechaHasta =
                "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

            if (filtro == 'Hoy') {
              fechaDesde = fechaHasta;
            } else if (filtro == 'Ayer') {
              final ayer = now.subtract(const Duration(days: 1));
              fechaDesde =
                  "${ayer.year}-${ayer.month.toString().padLeft(2, '0')}-${ayer.day.toString().padLeft(2, '0')}";
              fechaHasta = fechaDesde;
            } else if (filtro == 'Este Mes') {
              fechaDesde =
                  "${now.year}-${now.month.toString().padLeft(2, '0')}-01";
            } else if (filtro == 'Este Año') {
              fechaDesde = "${now.year}-01-01";
            }
            _fechaDesdeController.text = fechaDesde;
            _fechaHastaController.text = fechaHasta;
            ref.read(facturacionHistorialProvider.notifier).updateFilters(
              token,
              {'fecha_desde': fechaDesde, 'fecha_hasta': fechaHasta},
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildFilters(String? token, FacturacionHistorialState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _compactDatePicker(
                'Desde',
                _fechaDesdeController,
                token,
                'fecha_desde',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _compactDatePicker(
                'Hasta',
                _fechaHastaController,
                token,
                'fecha_hasta',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.filters['estado'],
              hint: const Text(
                'Estado',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              isExpanded: true,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
              dropdownColor: Colors.white,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.grey,
                size: 18,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'pagada', child: Text('Pagada')),
                DropdownMenuItem(value: 'anulada', child: Text('Anulada')),
              ],
              onChanged: (val) {
                if (token != null) {
                  if (val == null) {
                    final newFilters = Map<String, String>.from(state.filters);
                    newFilters.remove('estado');
                    ref
                        .read(facturacionHistorialProvider.notifier)
                        .updateFilters(token, newFilters, replace: true);
                  } else {
                    ref
                        .read(facturacionHistorialProvider.notifier)
                        .updateFilters(token, {'estado': val});
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            if (token != null) {
              _fechaDesdeController.clear();
              _fechaHastaController.clear();
              _searchController.clear();
              ref
                  .read(facturacionHistorialProvider.notifier)
                  .clearFilters(token);
            }
          },
          icon: const Icon(Icons.clear_all, size: 16),
          label: const Text(
            'Limpiar',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red.shade700,
            elevation: 0,
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactDatePicker(
    String hint,
    TextEditingController controller,
    String? token,
    String filterKey,
  ) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          prefixIcon: const Icon(
            Icons.calendar_today,
            size: 16,
            color: Colors.grey,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onTap: () async {
          final date = await showCustomDatePicker(context);
          if (date != null && token != null) {
            final formatted = formatDate(date);
            controller.text = formatted;
            ref.read(facturacionHistorialProvider.notifier).updateFilters(
              token,
              {filterKey: formatted},
            );
          }
        },
      ),
    );
  }

  Widget _buildTable(List<Factura> facturas) {
    if (facturas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron ventas.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    horizontalMargin: 16,
                    columnSpacing: 24,
                    headingRowHeight: 44,
                    dataRowMaxHeight: 52,
                    dataRowMinHeight: 44,
                    headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade50,
                    ),
                    dividerThickness: 0.5,
                    columns: [
                      _modernColumn('ID'),
                      _modernColumn('FECHA'),
                      _modernColumn('CLIENTE'),
                      _modernColumn('NCF'),
                      _modernColumn('TOTAL'),
                      _modernColumn('ESTADO'),
                      _modernColumn('VENDEDOR'),
                      _modernColumn('ACCIONES'),
                    ],
                    rows: facturas.map((f) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '#${f.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              formatFechaHora(f.fechaEmision ?? DateTime.now()),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              f.cliente?.nombre ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              f.ncf ?? 'N/A',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              formatCurrency(double.parse(f.total ?? '0')),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(_buildStatusChip(f.estado)),
                          DataCell(
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 8,
                                  backgroundColor: AppColors.primary,
                                  child: Icon(
                                    Icons.person,
                                    size: 8,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  f.user?.name ?? 'N/A',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                _tableIconButton(
                                  icon: Icons.visibility_rounded,
                                  color: Colors.blue,
                                  tooltip: 'Ver Detalle',
                                  onTap: () => _showDetalles(context, f),
                                ),
                                const SizedBox(width: 6),
                                _tableIconButton(
                                  icon: Icons.print_rounded,
                                  color: AppColors.primary,
                                  tooltip: 'Imprimir',
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPagination(String? token, FacturacionHistorialState state) {
    if (state.total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${state.total} facturas',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: state.currentPage > 1 && token != null
                    ? () => ref
                          .read(facturacionHistorialProvider.notifier)
                          .setPage(token, state.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.secondary,
                splashRadius: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Página ${state.currentPage} de ${state.lastPage}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: state.currentPage < state.lastPage && token != null
                    ? () => ref
                          .read(facturacionHistorialProvider.notifier)
                          .setPage(token, state.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.secondary,
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  DataColumn _modernColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? estado) {
    final color = _getEstadoColor(estado);
    final text = estado?.toUpperCase() ?? 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  Color _getEstadoColor(String? estado) {
    switch (estado) {
      case 'pagada':
        return const Color(0xFF10B981);
      case 'pendiente':
        return Colors.amber;
      case 'anulada':
        return const Color(0xFFF43F5E);
      default:
        return Colors.blueGrey;
    }
  }

  void _showDetalles(BuildContext context, Factura f) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detalle de Factura #${f.id}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.secondary,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detalleItem('Cliente:', f.cliente?.nombre ?? 'N/A'),
                _detalleItem('NCF:', f.ncf ?? 'N/A'),
                _detalleItem('Tipo:', f.tipoFactura ?? 'N/A'),
                _detalleItem(
                  'Fecha:',
                  formatFechaHora(f.fechaEmision ?? DateTime.now()),
                ),
                const Divider(height: 24),
                const Text(
                  'Detalles de Artículos:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ...(f.detalles ?? []).map(
                  (d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${d.cantidad} x ${d.descripcion}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          formatCurrency(d.total ?? 0.0),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                _detalleItem(
                  'Subtotal:',
                  formatCurrency(double.parse(f.subtotal ?? '0')),
                ),
                _detalleItem(
                  'ITBIS:',
                  formatCurrency(double.parse(f.itbis ?? '0')),
                ),
                _detalleItem(
                  'Total:',
                  formatCurrency(double.parse(f.total ?? '0')),
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalleItem(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
              color: isTotal ? AppColors.secondary : Colors.black87,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
