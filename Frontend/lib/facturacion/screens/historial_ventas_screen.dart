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
        title: const Text('HISTORIAL DE VENTAS'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.azulOscuro,
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
        ],
      ),
      body: state.isLoading && state.historial.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTopCards(state),
                _buildQuickFilters(token),
                _buildFilters(token, state),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTable(state.historial),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResumenFooter(FacturacionHistorialState state) {
    final resumen = state.resumen;
    final totales = resumen?['totales'];
    final porMetodo = resumen?['por_metodo'] as List?;

    if (resumen == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _resumenMiniItem(
                  'FACTURAS',
                  '${totales?['cantidad_facturas'] ?? 0}',
                  isWhite: true,
                ),
                if (porMetodo != null)
                  ...porMetodo.map(
                    (m) => _resumenMiniItem(
                      (m['metodo_pago'] as String).toUpperCase(),
                      formatCurrency(double.parse(m['total'].toString())),
                      isWhite: true,
                    ),
                  ),
                _resumenMiniItem(
                  'TOTAL BRUTO',
                  formatCurrency(
                    double.parse((totales?['total_venta'] ?? 0).toString()),
                  ),
                  isPrimary: true,
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniTextDetail(
                  'Subtotal: ${formatCurrency(double.parse((totales?['total_venta'] ?? 0).toString()))}',
                ),
                const SizedBox(width: 20),
                _miniTextDetail(
                  'ITBIS: ${formatCurrency(double.parse((totales?['total_itbis'] ?? 0).toString()))}',
                ),
                const SizedBox(width: 20),
                _miniTextDetail(
                  'Desc: ${formatCurrency(double.parse((totales?['total_descuento'] ?? 0).toString()))}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTextDetail(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 11),
    );
  }

  Widget _resumenMiniItem(
    String label,
    String value, {
    bool isPrimary = false,
    bool isWhite = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isWhite ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrimary ? 20 : 14,
            fontWeight: FontWeight.w900,
            color: isPrimary
                ? AppColors.primary
                : (isWhite ? Colors.white : AppColors.azulOscuro),
          ),
        ),
      ],
    );
  }

  Widget _buildTopCards(FacturacionHistorialState state) {
    final resumen = state.resumen;
    final totales = resumen?['totales'];
    final porMetodo = resumen?['por_metodo'] as List? ?? [];

    if (resumen == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiCard(
              title: 'FACTURAS',
              value: '${totales?['cantidad_facturas'] ?? 0}',
              icon: Icons.receipt_long_rounded,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildKpiCard(
              title: 'TOTAL VENDIDO',
              value: formatCurrency(
                double.parse((totales?['total_venta'] ?? 0).toString()),
              ),
              icon: Icons.attach_money_rounded,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildKpiCard(
              title: 'MÉTODOS DE PAGO',
              value: porMetodo.isEmpty
                  ? 'RD\$ 0.00'
                  : porMetodo
                        .map(
                          (m) =>
                              "${(m['metodo_pago'] as String).substring(0, 3).toUpperCase()}: ${formatCurrency(double.parse(m['total'].toString()))}",
                        )
                        .join('\n'),
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.orange,
              valueSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildKpiCard(
              title: 'ITBIS Y DESCUENTOS',
              value:
                  'ITBIS: ${formatCurrency(double.parse((totales?['total_itbis'] ?? 0).toString()))}\nDesc: ${formatCurrency(double.parse((totales?['total_descuento'] ?? 0).toString()))}',
              icon: Icons.percent_rounded,
              color: Colors.purple,
              valueSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double valueSize = 20,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.azulOscuro,
                    fontSize: valueSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(String? token) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: ['Hoy', 'Ayer', 'Esta Semana', 'Este Mes'].map((filtro) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                filtro,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade300),
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
                } else if (filtro == 'Esta Semana') {
                  final inicioSemana = now.subtract(
                    Duration(days: now.weekday - 1),
                  );
                  fechaDesde =
                      "${inicioSemana.year}-${inicioSemana.month.toString().padLeft(2, '0')}-${inicioSemana.day.toString().padLeft(2, '0')}";
                } else if (filtro == 'Este Mes') {
                  fechaDesde =
                      "${now.year}-${now.month.toString().padLeft(2, '0')}-01";
                }
                _fechaDesdeController.text = fechaDesde;
                _fechaHastaController.text = fechaHasta;
                ref.read(facturacionHistorialProvider.notifier).updateFilters(
                  token,
                  {'fecha_desde': fechaDesde, 'fecha_hasta': fechaHasta},
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilters(String? token, FacturacionHistorialState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: textFieldWidgetUI(
              label: 'Fecha Desde',
              controller: _fechaDesdeController,
              readOnly: true,
              prefixIcon: Icons.calendar_today,
              onTap: () async {
                final date = await showCustomDatePicker(context);
                if (date != null && token != null) {
                  final formatted = formatDate(date);
                  _fechaDesdeController.text = formatted;
                  ref.read(facturacionHistorialProvider.notifier).updateFilters(
                    token,
                    {'fecha_desde': formatted},
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: textFieldWidgetUI(
              label: 'Fecha Hasta',
              controller: _fechaHastaController,
              readOnly: true,
              prefixIcon: Icons.calendar_today,
              onTap: () async {
                final date = await showCustomDatePicker(context);
                if (date != null && token != null) {
                  final formatted = formatDate(date);
                  _fechaHastaController.text = formatted;
                  ref.read(facturacionHistorialProvider.notifier).updateFilters(
                    token,
                    {'fecha_hasta': formatted},
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.filters['estado'],
                  hint: const Text('Estado'),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(
                      value: 'pendiente',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(value: 'pagada', child: Text('Pagada')),
                    DropdownMenuItem(value: 'anulada', child: Text('Anulada')),
                  ],
                  onChanged: (val) {
                    if (token != null) {
                      if (val == null) {
                        final newFilters = Map<String, String>.from(
                          state.filters,
                        );
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
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (token != null) {
                _fechaDesdeController.clear();
                _fechaHastaController.clear();
                ref
                    .read(facturacionHistorialProvider.notifier)
                    .clearFilters(token);
              }
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpiar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
            ),
          ),
        ],
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
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 24,
            columnSpacing: 40,
            headingRowHeight: 60,
            dataRowMaxHeight: 70,
            dataRowMinHeight: 60,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
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
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      formatFechaHora(f.fechaEmision ?? DateTime.now()),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      f.cliente?.nombre ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      f.ncf ?? 'N/A',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      formatCurrency(double.parse(f.total ?? '0')),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  DataCell(_buildStatusChip(f.estado)),
                  DataCell(
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          f.user?.name ?? 'N/A',
                          style: const TextStyle(fontSize: 13),
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
                        const SizedBox(width: 8),
                        _tableIconButton(
                          icon: Icons.print_rounded,
                          color: AppColors.primary,
                          tooltip: 'Imprimir',
                          onTap: () {
                            // Puedes alternar entre PDF o ESC/POS aquí
                            // FacturaTicket.imprimir(f); // Opción PDF
                            // FacturaEscPos.imprimirRed(
                            //   f,
                            //   '192.168.100.7',
                            // ); // Opción Directa
                          },
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
  }

  DataColumn _modernColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? estado) {
    final color = _getEstadoColor(estado);
    final text = estado?.toUpperCase() ?? 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
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
        return const Color(0xFF10B981); // Emerald
      case 'pendiente':
        return Colors.amber;
      case 'anulada':
        return const Color(0xFFF43F5E); // Rose
      default:
        return Colors.blueGrey;
    }
  }

  void _showDetalles(BuildContext context, Factura f) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalle de Factura #${f.id}'),
        content: SizedBox(
          width: 500,
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
                const Divider(),
                const Text(
                  'Detalles de Artículos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...(f.detalles ?? []).map(
                  (d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${d.cantidad} x ${d.descripcion}'),
                        ),
                        Text(formatCurrency(d.total ?? 0.0)),
                      ],
                    ),
                  ),
                ),
                const Divider(),
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
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
