import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../model/factura.dart';
import '../providers/gestion_documentos_provider.dart';
import 'widgets/factura_list_item.dart';
import 'widgets/factura_detalle_panel.dart';

class GestionDocumentosScreen extends ConsumerStatefulWidget {
  const GestionDocumentosScreen({super.key});

  @override
  ConsumerState<GestionDocumentosScreen> createState() => _GestionDocumentosScreenState();
}

class _GestionDocumentosScreenState extends ConsumerState<GestionDocumentosScreen> {
  final TextEditingController _searchController = TextEditingController();
  Factura? _selectedFactura;
  String _selectedDateFilter = 'Todos'; // Manteniendo el diseño de filtros de compras

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(gestionDocumentosProvider.notifier).buscar(token);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String token) {
    setState(() {
      _selectedFactura = null;
      _selectedDateFilter = 'Búsqueda';
    });
    ref.read(gestionDocumentosProvider.notifier).buscar(token, query: _searchController.text);
  }

  void _aplicarFiltroFecha(String filtro, String token) {
    setState(() {
      _selectedDateFilter = filtro;
      _selectedFactura = null;
      _searchController.clear();
    });

    String? fechaDesde;
    String? fechaHasta;
    final now = DateTime.now();

    if (filtro == 'Hoy') {
      fechaDesde = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      fechaHasta = fechaDesde;
    } else if (filtro == 'Ayer') {
      final ayer = now.subtract(const Duration(days: 1));
      fechaDesde = "${ayer.year}-${ayer.month.toString().padLeft(2, '0')}-${ayer.day.toString().padLeft(2, '0')}";
      fechaHasta = fechaDesde;
    } else if (filtro == 'Este Mes') {
      fechaDesde = "${now.year}-${now.month.toString().padLeft(2, '0')}-01";
      // El backend filtra hasta 23:59:59 si se le manda hoy, así que mandamos hoy.
      fechaHasta = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    }

    ref.read(gestionDocumentosProvider.notifier).buscar(
      token, 
      fechaDesde: fechaDesde, 
      fechaHasta: fechaHasta
    );
  }

  Future<void> _seleccionarFechaCalendario(BuildContext context, String token) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final fechaStr = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _selectedDateFilter = 'Calendario';
        _selectedFactura = null;
        _searchController.clear();
      });
      ref.read(gestionDocumentosProvider.notifier).buscar(
        token, 
        fechaDesde: fechaStr, 
        fechaHasta: fechaStr
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authProvider).token;
    final state = ref.watch(gestionDocumentosProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text(
          'Gestión de Documentos',
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
              if (token != null) {
                _searchController.clear();
                ref.read(gestionDocumentosProvider.notifier).buscar(token);
                setState(() {
                  _selectedFactura = null;
                  _selectedDateFilter = 'Todos';
                });
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 800;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IZQUIERDA: LISTA Y BUSCADOR
                Expanded(
                  flex: isTablet ? 4 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBuscador(token),
                      const SizedBox(height: 16),
                      _buildDateFilters(token),
                      const SizedBox(height: 24),
                      Expanded(
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : state.error != null
                                ? Center(
                                    child: Text(
                                      'Error: ${state.error}',
                                      style: TextStyle(color: AppColors.danger),
                                    ),
                                  )
                                : state.resultados.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No se encontraron documentos',
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: state.resultados.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final factura = state.resultados[index];
                                          final isSelected = _selectedFactura?.id == factura.id;

                                          return FacturaListItem(
                                            factura: factura,
                                            isSelected: isSelected,
                                            onTap: () {
                                              setState(() {
                                                _selectedFactura = factura;
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

                // DERECHA: DETALLES Y ACCIONES (PANEL)
                if (isTablet)
                  Expanded(
                    flex: 5,
                    child: FacturaDetallePanel(
                      factura: _selectedFactura,
                      isLoading: state.isLoading && state.resultados.isNotEmpty, 
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBuscador(String? token) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (_) => token != null ? _onSearch(token) : null,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: '🔍 NCF, Factura o Cliente...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () => token != null ? _onSearch(token) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilters(String? token) {
    final filters = ['Todos', 'Hoy', 'Ayer', 'Este Mes', 'Búsqueda'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...filters.map((filter) {
            final isSelected = _selectedDateFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (bool selected) {
                  if (selected && token != null) {
                    _aplicarFiltroFecha(filter, token);
                  }
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
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
          }),
          Container(
            margin: const EdgeInsets.only(left: 4.0),
            decoration: BoxDecoration(
              color: _selectedDateFilter == 'Calendario' ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedDateFilter == 'Calendario' ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.calendar_month),
              color: _selectedDateFilter == 'Calendario' ? AppColors.primary : Colors.grey.shade600,
              tooltip: 'Elegir fecha específica',
              onPressed: () {
                if (token != null) {
                  _seleccionarFechaCalendario(context, token);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
