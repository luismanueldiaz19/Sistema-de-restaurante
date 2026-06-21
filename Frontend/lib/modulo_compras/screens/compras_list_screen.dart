import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/compra.dart';
import '../providers/compras_provider.dart';
import 'nueva_compra_screen.dart';
import 'widgets/compra_list_item.dart';
import 'widgets/compra_detalle_panel.dart';

class ComprasListScreen extends ConsumerStatefulWidget {
  const ComprasListScreen({super.key});

  @override
  ConsumerState<ComprasListScreen> createState() => _ComprasListScreenState();
}

class _ComprasListScreenState extends ConsumerState<ComprasListScreen> {
  Compra? _selectedCompra;
  String _selectedDateFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(comprasProvider.notifier).loadCompras();
    });
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
      case 'Rango...':
        _mostrarSelectorRangoFechas();
        return; // No cargar hasta seleccionar rango
      default: // 'Todos'
        fechaDesde = null;
        fechaHasta = null;
    }

    ref
        .read(comprasProvider.notifier)
        .loadCompras(fechaDesde: fechaDesde, fechaHasta: fechaHasta);
  }

  Future<void> _mostrarSelectorRangoFechas() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(comprasProvider.notifier)
          .loadCompras(
            fechaDesde: picked.start.toString().split(' ')[0],
            fechaHasta: picked.end.toString().split(' ')[0],
          );
    } else {
      // Si cancela, volvemos a 'Todos'
      setState(() => _selectedDateFilter = 'Todos');
      ref.read(comprasProvider.notifier).loadCompras();
    }
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
                            _buildDateFilters(),
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
                                      itemCount: state.compras.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
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

  Widget _buildDateFilters() {
    final filters = ['Todos', 'Hoy', 'Ayer', 'Este Mes', 'Rango...'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedDateFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) {
                  _aplicarFiltroFecha(filter);
                }
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResumenTarjetas(ComprasState state) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total General',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      formatCurrency(state.totales.totalGeneral),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagado',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      formatCurrency(state.totales.totalPagado),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
