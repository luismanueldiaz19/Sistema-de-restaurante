import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../facturacion/models/factura_item.dart';
import '../../facturacion/providers/facturacion_provider.dart';
import '../../facturacion/screens/add_factura.dart';
import '../../facturacion/services/printer_ticket_pedido.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../models/pedido.dart';
import '../providers/pedidos_provider.dart';
import 'add_pedido.dart';

class PedidosScreen extends ConsumerStatefulWidget {
  const PedidosScreen({super.key});

  @override
  ConsumerState<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends ConsumerState<PedidosScreen> {
  int? _selectedPedidoId;
  String _searchQuery = '';
  String _selectedStatusFilter =
      'Todos'; // 'Todos', 'Pendiente', 'Preparando', 'Facturado', 'Cancelado'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pedidosProvider).initPolling();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _changeDateByDays(int days) {
    final provider = ref.read(pedidosProvider);
    final newDate = provider.currentDate.add(Duration(days: days));
    provider.changeDate(newDate);
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange.shade800;
      case 'Confirmado':
      case 'Preparando':
        return Colors.blue.shade700;
      case 'Facturado':
        return Colors.green.shade700;
      case 'Cancelado':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBgColor(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange.shade50;
      case 'Confirmado':
      case 'Preparando':
        return Colors.blue.shade50;
      case 'Facturado':
        return Colors.green.shade50;
      case 'Cancelado':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _getDeliveryIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'domicilio':
        return Icons.delivery_dining;
      case 'local':
        return Icons.table_restaurant;
      case 'recoger':
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  List<Pedido> _getFilteredPedidos(List<Pedido> pedidos) {
    return pedidos.where((p) {
      // Filtro por Estado
      if (_selectedStatusFilter != 'Todos') {
        if (_selectedStatusFilter == 'Preparando') {
          if (p.estado != 'Preparando' && p.estado != 'Confirmado') {
            return false;
          }
        } else if (p.estado != _selectedStatusFilter) {
          return false;
        }
      }

      // Filtro por Buscador
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesCliente = p.clienteNombre.toLowerCase().contains(query);
        final matchesTel = p.clienteTelefono.toLowerCase().contains(query);
        final matchesSecuencia =
            '#${p.secuenciaDiaria}'.contains(query) ||
            p.secuenciaDiaria.toString() == query;
        final matchesCodigo = (p.codigoBarras ?? '').toLowerCase().contains(
          query,
        );
        if (!matchesCliente &&
            !matchesTel &&
            !matchesSecuencia &&
            !matchesCodigo) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _imprimirPedido(Pedido pedido) async {
    final isCopy = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.print, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Imprimir Comanda',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          '¿Deseas imprimir el comprobante como Original o como Copia de cocina?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Original'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copia'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );

    if (isCopy == null) return;

    final printer = PedidoPrinterService.instance;
    final result = await printer.imprimirPedido(pedido, esCopia: isCopy);

    if (mounted) {
      if (result.exito) {
        showToast(
          context,
          'Ticket impreso correctamente',
          bgColor: Colors.green,
        );
      } else {
        showToast(context, result.mensaje, bgColor: Colors.orange);
      }
    }
  }

  Future<void> _cambiarEstado(Pedido pedido, String nuevoEstado) async {
    try {
      await ref
          .read(pedidosProvider)
          .updatePedidoStatus(pedido.id!, nuevoEstado);
      if (mounted) {
        showToast(
          context,
          'Estado actualizado a $nuevoEstado',
          bgColor: Colors.blue,
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Error al actualizar: $e', bgColor: Colors.red);
      }
    }
  }

  Future<void> _cancelarPedido(Pedido pedido) async {
    final confirm = await CustomConfirmDialog.show(
      context,
      title: 'Cancelar Pedido #${pedido.secuenciaDiaria}',
      message:
          '¿Estás seguro de que deseas cancelar este pedido? Esta acción no se puede deshacer.',
      confirmText: 'Sí, Cancelar',
      cancelText: 'Volver',
      icon: Icons.cancel_outlined,
      primaryColor: AppColors.danger,
    );

    if (confirm == true) {
      await _cambiarEstado(pedido, 'Cancelado');
    }
  }

  Future<void> _facturarPedido(Pedido pedido) async {
    final confirm = await CustomConfirmDialog.show(
      context,
      title: 'Facturar Pedido #${pedido.secuenciaDiaria}',
      message:
          'Se transferirán los artículos del pedido directamente a la caja para procesar el cobro.',
      confirmText: 'Facturar en Caja',
      cancelText: 'Cancelar',
      icon: Icons.receipt_long,
      primaryColor: AppColors.success,
    );

    if (confirm != true) return;

    final factNotifier = ref.read(facturacionProvider.notifier);
    factNotifier.limpiarCarrito();

    for (var det in pedido.detalles) {
      final item = FacturaItem(
        id: (det.productoId ?? 0).toString(),
        descripcion: det.nombreProducto,
        precio: det.precioUnitario,
        cantidad: det.cantidad,
      );
      factNotifier.agregarProducto(item);
    }

    await ref.read(pedidosProvider).updatePedidoStatus(pedido.id!, 'Facturado');

    if (mounted) {
      showToast(
        context,
        'Pedido transferido a facturación',
        bgColor: Colors.green,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const CrearFacturaPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(pedidosProvider);
    final allPedidos = provider.pedidos;
    final filteredPedidos = _getFilteredPedidos(allPedidos);

    // Auto-seleccionar primer pedido en desktop si no hay selección
    if (_selectedPedidoId != null &&
        !allPedidos.any((p) => p.id == _selectedPedidoId)) {
      _selectedPedidoId = null;
    }

    Pedido? selectedPedido;
    if (_selectedPedidoId != null) {
      try {
        selectedPedido = allPedidos.firstWhere(
          (p) => p.id == _selectedPedidoId,
        );
      } catch (_) {
        selectedPedido = null;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(provider),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 820;

          if (isDesktop) {
            // Diseño Dividido para Desktop/Tablet
            return Column(
              children: [
                _buildMetricsBar(allPedidos),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Panel Izquierdo: Lista de Pedidos
                      SizedBox(
                        width: constraints.maxWidth * 0.42 > 420
                            ? 420
                            : constraints.maxWidth * 0.42,
                        child: _buildLeftListPanel(
                          filteredPedidos,
                          provider.isLoading,
                        ),
                      ),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Color(0xFFE5E7EB),
                      ),
                      // Panel Derecho: Estación de Procesamiento
                      Expanded(
                        child: selectedPedido == null
                            ? _buildEmptyState()
                            : _buildProcessingPanel(selectedPedido),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Diseño Móvil / Pantallas Angostas
            if (selectedPedido != null) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: Colors.white,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          onPressed: () =>
                              setState(() => _selectedPedidoId = null),
                        ),
                        Text(
                          'Pedido #${selectedPedido.secuenciaDiaria}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildProcessingPanel(selectedPedido)),
                ],
              );
            }

            return Column(
              children: [
                _buildMetricsBar(allPedidos),
                const Divider(height: 1),
                Expanded(
                  child: _buildLeftListPanel(
                    filteredPedidos,
                    provider.isLoading,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(PedidosProvider provider) {
    final fechaStr = FormatterNumber.formatFechaLatina(provider.currentDate);
    final dateLabel = _isToday(provider.currentDate)
        ? 'Hoy ($fechaStr)'
        : fechaStr;

    return AppBar(
      elevation: 0.5,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.secondary,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestión de Pedidos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
              Text(
                'Panel de cocina, entrega y facturación',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Navegador Rápido de Fechas
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Día anterior',
                onPressed: () => _changeDateByDays(-1),
              ),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: provider.currentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) provider.changeDate(date);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Día siguiente',
                onPressed: () => _changeDateByDays(1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh, size: 19),
          tooltip: 'Actualizar pedidos',
          onPressed: () => ref.read(pedidosProvider).fetchPedidos(),
        ),
        const SizedBox(width: 4),
        // Botón Nuevo Pedido
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const CrearPedidoPage()),
              );
              if (result == true) {
                ref.read(pedidosProvider).fetchPedidos();
              }
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'Nuevo Pedido',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMetricsBar(List<Pedido> pedidos) {
    final pendientes = pedidos.where((p) => p.estado == 'Pendiente').length;
    final preparando = pedidos
        .where((p) => p.estado == 'Preparando' || p.estado == 'Confirmado')
        .length;
    final facturados = pedidos.where((p) => p.estado == 'Facturado').length;
    final totalVentas = pedidos
        .where((p) => p.estado != 'Cancelado')
        .fold(0.0, (sum, p) => sum + p.total);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMetricItem(
              'Total Pedidos',
              '${pedidos.length}',
              Icons.format_list_numbered,
              Colors.grey.shade800,
            ),
            _buildMetricDivider(),
            _buildMetricItem(
              'Pendientes',
              '$pendientes',
              Icons.pending_actions,
              Colors.orange.shade800,
            ),
            _buildMetricDivider(),
            _buildMetricItem(
              'En Cocina',
              '$preparando',
              Icons.outdoor_grill,
              Colors.blue.shade700,
            ),
            _buildMetricDivider(),
            _buildMetricItem(
              'Facturados',
              '$facturados',
              Icons.check_circle_outline,
              Colors.green.shade700,
            ),
            _buildMetricDivider(),
            _buildMetricItem(
              'Venta del Día',
              FormatterNumber.formatCurrency(totalVentas),
              Icons.payments_outlined,
              AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.grey.shade200,
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLeftListPanel(List<Pedido> pedidos, bool isLoading) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Buscador y Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente, teléfono o #...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: Colors.grey,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 15,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ),
          // Chips de Estados
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                _buildStatusFilterChip('Todos'),
                _buildStatusFilterChip('Pendiente', label: 'Pendientes'),
                _buildStatusFilterChip('Preparando', label: 'En Cocina'),
                _buildStatusFilterChip('Facturado', label: 'Facturados'),
                _buildStatusFilterChip('Cancelado', label: 'Cancelados'),
              ],
            ),
          ),
          const Divider(height: 8, thickness: 1, color: Color(0xFFF3F4F6)),
          // Lista de Tarjetas
          Expanded(
            child: isLoading && pedidos.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : pedidos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 40,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay pedidos registrados',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    itemCount: pedidos.length,
                    itemBuilder: (context, index) {
                      final pedido = pedidos[index];
                      final isSelected = pedido.id == _selectedPedidoId;
                      return _buildPedidoCard(pedido, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String status, {String? label}) {
    final isSelected = _selectedStatusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedStatusFilter = status),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label ?? status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPedidoCard(Pedido pedido, bool isSelected) {
    final statusColor = _getStatusColor(pedido.estado);
    final statusBgColor = _getStatusBgColor(pedido.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedPedidoId = pedido.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: # y Total
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '# ${pedido.secuenciaDiaria}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getDeliveryIcon(pedido.tipoEntrega),
                          size: 12,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pedido.tipoEntrega,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    FormatterNumber.formatCurrency(pedido.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Cliente y Teléfono
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 13,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pedido.clienteNombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pedido.clienteTelefono.isNotEmpty) ...[
                    Text(
                      pedido.clienteTelefono,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              // Estado y cantidad de artículos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pedido.detalles.length} artículo${pedido.detalles.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pedido.estado,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.touch_app_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Selecciona un pedido de la lista',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Podrás ver sus artículos, notas, imprimir comanda y facturar directamente.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingPanel(Pedido pedido) {
    final statusColor = _getStatusColor(pedido.estado);
    final statusBgColor = _getStatusBgColor(pedido.estado);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Cabecera del Panel de Procesamiento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'ORDEN # ${pedido.secuenciaDiaria}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getDeliveryIcon(pedido.tipoEntrega),
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pedido.tipoEntrega.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Selector rápido de estado
                PopupMenuButton<String>(
                  tooltip: 'Cambiar estado manualmente',
                  onSelected: (val) => _cambiarEstado(pedido, val),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'Pendiente',
                      child: Text('Pendiente'),
                    ),
                    const PopupMenuItem(
                      value: 'Preparando',
                      child: Text('Preparando'),
                    ),
                    const PopupMenuItem(
                      value: 'Facturado',
                      child: Text('Facturado'),
                    ),
                    const PopupMenuItem(
                      value: 'Cancelado',
                      child: Text('Cancelado'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      children: [
                        Text(
                          pedido.estado,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido con Scroll
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta Información de Cliente y Entrega
                  _buildCustomerDeliveryCard(pedido),
                  const SizedBox(height: 14),

                  // Alerta de Nota Especial si existe
                  if (pedido.nota != null &&
                      pedido.nota!.trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.announcement_outlined,
                            color: Colors.amber.shade900,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INDICACIONES O NOTA ESPECIAL:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pedido.nota!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Comanda de Artículos
                  _buildItemsCard(pedido),
                ],
              ),
            ),
          ),
          // Barra Inferior de Procesamiento y Acciones Rápidas
          _buildActionProcessingBar(pedido),
        ],
      ),
    );
  }

  Widget _buildCustomerDeliveryCard(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pedido.clienteNombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              if (pedido.codigoBarras != null &&
                  pedido.codigoBarras!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        pedido.codigoBarras!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                pedido.clienteTelefono.isNotEmpty
                    ? pedido.clienteTelefono
                    : 'Sin teléfono',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              if (pedido.clienteTelefono.isNotEmpty) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: pedido.clienteTelefono),
                    );
                    showToast(context, 'Teléfono copiado');
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.copy, size: 12, color: AppColors.primary),
                  ),
                ),
              ],
              const Spacer(),
              if (pedido.fecha.isNotEmpty) ...[
                Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  pedido.fecha,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
          if (pedido.direccion != null &&
              pedido.direccion!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pedido.direccion!,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard(Pedido pedido) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_menu,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Comanda / Artículos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${pedido.detalles.length} ítem${pedido.detalles.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pedido.detalles.length,
            separatorBuilder: (ctx, i) => const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF3F4F6),
            ),
            itemBuilder: (ctx, index) {
              final det = pedido.detalles[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${det.cantidad.toStringAsFixed(det.cantidad % 1 == 0 ? 0 : 2)}x',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        det.nombreProducto,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      FormatterNumber.formatCurrency(det.precioUnitario),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      FormatterNumber.formatCurrency(det.subtotal),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          // Total de la orden
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL A COBRAR:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  FormatterNumber.formatCurrency(pedido.total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionProcessingBar(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón Imprimir Ticket
          OutlinedButton.icon(
            onPressed: () => _imprimirPedido(pedido),
            icon: const Icon(Icons.print, size: 16),
            label: const Text(
              'Imprimir Ticket',
              style: TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade800,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const Spacer(),

          // Si el pedido está Cancelado
          if (pedido.estado == 'Cancelado') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Pedido Cancelado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ]
          // Si el pedido está Facturado
          else if (pedido.estado == 'Facturado') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Facturado en Caja',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ]
          // Si el pedido está Pendiente
          else if (pedido.estado == 'Pendiente') ...[
            OutlinedButton(
              onPressed: () => _cancelarPedido(pedido),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _cambiarEstado(pedido, 'Preparando'),
              icon: const Icon(Icons.outdoor_grill, size: 16),
              label: const Text(
                'Iniciar Preparación',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ]
          // Si el pedido está Preparando o Confirmado
          else if (pedido.estado == 'Preparando' ||
              pedido.estado == 'Confirmado') ...[
            OutlinedButton(
              onPressed: () => _cancelarPedido(pedido),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _facturarPedido(pedido),
              icon: const Icon(Icons.receipt_long, size: 16),
              label: const Text(
                'Facturar en Caja',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
