import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/compra.dart';
import '../providers/compras_provider.dart';
import 'nueva_compra_screen.dart';
import 'widgets/compra_list_item.dart';
import 'widgets/compra_detalle_panel.dart';
import 'widgets/filtros/compra_filtros.dart';

class ComprasListScreen extends ConsumerStatefulWidget {
  const ComprasListScreen({super.key});

  @override
  ConsumerState<ComprasListScreen> createState() => _ComprasListScreenState();
}

class _ComprasListScreenState extends ConsumerState<ComprasListScreen> {
  Compra? _selectedCompra;
  String _selectedDateFilter = 'Todos';
  String _selectedStatus = 'todos';
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(comprasProvider.notifier).loadCompras();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(comprasProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _aplicarFiltroFecha(String filtro) {
    setState(() {
      _selectedDateFilter = filtro;
      _selectedCompra = null;
    });

    final now = DateTime.now();
    String? fechaDesde;
    String? fechaHasta;

    switch (filtro) {
      case 'Hoy':
        fechaDesde = now.toString().split(' ')[0];
        fechaHasta = fechaDesde;
        break;
      case 'Ayer':
        final ayer = now.subtract(const Duration(days: 1));
        fechaDesde = ayer.toString().split(' ')[0];
        fechaHasta = fechaDesde;
        break;
      case 'Este Mes':
        fechaDesde = DateTime(now.year, now.month, 1).toString().split(' ')[0];
        fechaHasta = DateTime(
          now.year,
          now.month + 1,
          0,
        ).toString().split(' ')[0];
        break;
      default: // 'Todos'
        fechaDesde = null;
        fechaHasta = null;
    }

    ref
        .read(comprasProvider.notifier)
        .loadCompras(
          fechaDesde: fechaDesde,
          fechaHasta: fechaHasta,
          search: _searchCtrl.text,
          estado: _selectedStatus,
        );
  }

  void _aplicarFiltroSearch(String text) {
    ref
        .read(comprasProvider.notifier)
        .loadCompras(search: text, estado: _selectedStatus);
  }

  void _aplicarFiltroEstado(String? estado) {
    if (estado == null) return;
    setState(() {
      _selectedStatus = estado;
      _selectedCompra = null;
    });
    ref
        .read(comprasProvider.notifier)
        .loadCompras(estado: estado, search: _searchCtrl.text);
  }
  void _aplicarFiltroRango(DateTime start, DateTime end) {
    setState(() {
      _selectedDateFilter = 'Rango...';
      _selectedCompra = null;
    });

    ref.read(comprasProvider.notifier).loadCompras(
      fechaDesde: start.toString().split(' ')[0],
      fechaHasta: end.toString().split(' ')[0],
      search: _searchCtrl.text,
      estado: _selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(comprasProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text(
          'Historial de Compras',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              ref.read(comprasProvider.notifier).loadCompras();
              setState(() {
                _selectedCompra = null;
                _selectedDateFilter = 'Todos';
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NuevaCompraScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva Compra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 800;

          return state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : state.error != null
              ? Center(
                  child: Text(
                    'Error: ${state.error}',
                    style: TextStyle(color: AppColors.danger),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IZQUIERDA: LISTA Y RESUMEN
                      Expanded(
                        flex: isTablet ? 4 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CompraFiltros(
                              searchCtrl: _searchCtrl,
                              selectedStatus: _selectedStatus,
                              selectedDateFilter: _selectedDateFilter,
                              onSearchSubmitted: _aplicarFiltroSearch,
                              onStatusChanged: _aplicarFiltroEstado,
                              onDateFilterSelected: _aplicarFiltroFecha,
                              onDateRangeSelected: _aplicarFiltroRango,
                            ),
                            const SizedBox(height: 16),
                            _buildResumenTarjetas(state),
                            const SizedBox(height: 24),
                            Expanded(
                              child: state.compras.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No hay compras registradas.',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    )
                                  : ListView.separated(
                                      controller: _scrollController,
                                      itemCount:
                                          state.compras.length +
                                          (state.hasMore ? 1 : 0),
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        if (index == state.compras.length) {
                                          return const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 16.0,
                                            ),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          );
                                        }
                                        final compra = state.compras[index];
                                        final isSelected =
                                            _selectedCompra?.id == compra.id;

                                        return CompraListItem(
                                          compra: compra,
                                          isSelected: isSelected,
                                          onTap: () {
                                            setState(() {
                                              _selectedCompra = compra;
                                            });
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),

                      if (isTablet) const SizedBox(width: 24),

                      // DERECHA: DETALLES (PANEL)
                      if (isTablet)
                        Expanded(
                          flex: 5,
                          child: CompraDetallePanel(
                            compra: _selectedCompra,
                            isLoading: false, // Detalle ya está en memoria
                          ),
                        ),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildResumenTarjetas(ComprasState state) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total General',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        FormatterNumber.formatCurrency(state.totales.totalGeneral),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pagado',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        FormatterNumber.formatCurrency(state.totales.totalPagado),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
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
}
