import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_date_range_picker.dart';

import '../../utils/normalize.dart';
import '../providers/historial_pagos_compras_provider.dart';
import '../../facturacion/providers/metodo_pago_provider.dart';
import '../models/pago_compra.dart';

class HistorialPagosCxpScreen extends ConsumerStatefulWidget {
  const HistorialPagosCxpScreen({super.key});

  @override
  ConsumerState<HistorialPagosCxpScreen> createState() =>
      _HistorialPagosCxpScreenState();
}

class _HistorialPagosCxpScreenState
    extends ConsumerState<HistorialPagosCxpScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  int? _selectedMetodoPago;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(historialPagosComprasProvider.notifier).loadPagos();
      ref.read(metodoPagoProvider).fetchMetodosActivos();
    });
  }

  void _applyFilters() {
    final searchRaw = _searchCtrl.text.trim();
    final searchNorm = TextNormalizer.normalizar(searchRaw);
    ref.read(historialPagosComprasProvider.notifier).updateFilters({
      if (searchNorm.isNotEmpty) 'search': searchNorm,
      if (_fechaInicio != null)
        'fecha_inicio': DateFormat('yyyy-MM-dd').format(_fechaInicio!),
      if (_fechaFin != null)
        'fecha_fin': DateFormat('yyyy-MM-dd').format(_fechaFin!),
      if (_selectedMetodoPago != null) 'metodo_pago_id': _selectedMetodoPago,
    });
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _selectedMetodoPago = null;
    });
    ref.read(historialPagosComprasProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historialPagosComprasProvider);
    final metodosPago = ref.watch(metodoPagoProvider).metodos;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Historial de Pagos a Proveedores',
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro, size: 20),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () =>
                ref.read(historialPagosComprasProvider.notifier).loadPagos(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar de Filtros (Parte 1)
          Container(
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),

                // Búsqueda Libre
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Proveedor o Factura',
                    labelStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 8,
                    ),
                  ),
                  onSubmitted: (_) => _applyFilters(),
                  onChanged: (val) {
                    if (val.isEmpty) {
                      _applyFilters();
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Rango de Fechas
                CustomDateRangePicker(
                  isPersonalizado: _fechaInicio != null && _fechaFin != null,
                  text: _fechaInicio != null && _fechaFin != null
                      ? '${DateFormat('dd/MM').format(_fechaInicio!)} - ${DateFormat('dd/MM').format(_fechaFin!)}'
                      : 'Rango de fechas',
                  width: double.infinity,
                  height: 42,
                  onDateRangeSelected: (start, end) {
                    setState(() {
                      _fechaInicio = start;
                      _fechaFin = end;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),

                // Dropdown Método de Pago
                DropdownButtonFormField<int>(
                  initialValue: _selectedMetodoPago,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Método de Pago',
                    labelStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Todos', style: TextStyle(fontSize: 12)),
                    ),
                    ...metodosPago.map(
                      (m) => DropdownMenuItem<int>(
                        value: m.id,
                        child: Text(
                          m.nombre ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedMetodoPago = val;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearFilters,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Limpiar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Filtrar',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenido Principal (Parte 2)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pagos Realizados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildResumen(state),
                  const SizedBox(height: 16),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(child: _buildList(state)),
                          if (state.total > 0) _buildPagination(state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumen(HistorialPagosComprasState state) {
    if (state.pagos.isEmpty) {
      return const Text(
        'Consulta todos los abonos y pagos registrados.',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    final int facturasUnicas =
        state.pagos.map((e) => e.numeroFactura).where((f) => f != 'N/A').toSet().length;
    final double montoTotal =
        state.pagos.fold(0.0, (sum, item) => sum + item.montoPagado);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'Pagos: ${state.total}',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.description, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'Facturas: $facturasUnicas',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.monetization_on, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'Total: ${FormatterNumber.formatCurrency(montoTotal)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(HistorialPagosComprasState state) {
    if (state.isLoading && state.pagos.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (state.pagos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No hay pagos registrados',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: state.pagos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pago = state.pagos[index];
        return _buildPagoCard(pago);
      },
    );
  }

  Widget _buildPagoCard(PagoCompra pago) {
    final prov = pago.proveedorNombre;
    final fac = pago.numeroFactura;
    final parsedDate = DateTime.tryParse(pago.fechaPago);
    final fecha = parsedDate != null
        ? DateFormat('yyyy-MM-dd').format(parsedDate)
        : pago.fechaPago;
    final metodo = pago.metodoPago;
    final ref = pago.referencia.isNotEmpty ? pago.referencia : 'S/R';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abono Fac: $fac',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prov,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 10,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fecha,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.account_balance_wallet,
                      size: 10,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      metodo,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FormatterNumber.formatCurrency(pago.montoPagado),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Ref: $ref',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(HistorialPagosComprasState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${state.total} pagos',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                onPressed: state.currentPage > 1
                    ? () => ref
                          .read(historialPagosComprasProvider.notifier)
                          .changePage(state.currentPage - 1)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                'Página ${state.currentPage} de ${state.lastPage}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                onPressed: state.currentPage < state.lastPage
                    ? () => ref
                          .read(historialPagosComprasProvider.notifier)
                          .changePage(state.currentPage + 1)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
