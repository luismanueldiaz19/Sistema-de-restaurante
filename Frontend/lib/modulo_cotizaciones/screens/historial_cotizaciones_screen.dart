import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../models/cotizacion_model.dart';
import '../providers/cotizacion_historial_provider.dart';
import '../services/cotizacion_service.dart';
import '../../utils/helpers.dart';
import '../../utils/normalize.dart';
import '../../palletes/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_date_range_picker.dart';
import '../../widgets/custom_filter_dropdown.dart';
import 'widgets/cotizacion_list_item.dart';
import 'widgets/cotizacion_detalle_panel.dart';

class HistorialCotizacionesScreen extends ConsumerStatefulWidget {
  const HistorialCotizacionesScreen({super.key});

  @override
  ConsumerState<HistorialCotizacionesScreen> createState() =>
      _HistorialCotizacionesScreenState();
}

class _HistorialCotizacionesScreenState
    extends ConsumerState<HistorialCotizacionesScreen> {
  Cotizacion? _selectedCotizacion;
  bool _isDetailLoading = false;
  String _selectedDateFilter = 'Últimos 30 días';
  String _searchQuery = "";
  String _selectedEstadoFilter = 'todos';
  final CotizacionService _service = CotizacionService();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialFilters();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final auth = ref.read(authProvider);
      ref.read(cotizacionHistorialProvider.notifier).loadMore(auth.token!);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _setInitialFilters() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final auth = ref.read(authProvider);

    final newFilters = {
      'fecha_desde': thirtyDaysAgo.toIso8601String().split('T')[0],
      'fecha_hasta': now.toIso8601String().split('T')[0],
      'estado': _selectedEstadoFilter,
    };

    ref
        .read(cotizacionHistorialProvider.notifier)
        .updateFilters(auth.token!, newFilters, replace: true);
  }

  Future<void> _cambiarEstado(String id, String estado) async {
    final auth = ref.read(authProvider);
    final success = await ref
        .read(cotizacionHistorialProvider.notifier)
        .updateEstado(auth.token!, id, estado);
    if (success && mounted) {
      showToast(context, 'Estado actualizado a $estado', bgColor: Colors.green);
      if (_selectedCotizacion?.id.toString() == id) {
        _loadCotizacionDetalle(id); // Reload details if selected
      }
    } else if (mounted) {
      showToast(context, 'Error al actualizar', bgColor: Colors.red);
    }
  }

  Future<void> _verPdf(Cotizacion cotizacion) async {
    final pdfUrlPath = cotizacion.pdfUrl;
    if (pdfUrlPath == null || pdfUrlPath.isEmpty) {
      if (mounted) {
        showToast(context, 'URL del PDF no disponible', bgColor: Colors.orange);
      }
      return;
    }
    final urlToLaunch = Uri.parse('$hostName$pdfUrlPath');
    if (await canLaunchUrl(urlToLaunch)) {
      await launchUrl(urlToLaunch, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        showToast(context, 'No se pudo abrir el PDF', bgColor: Colors.red);
      }
    }
  }

  Future<void> _loadCotizacionDetalle(String id) async {
    setState(() {
      _isDetailLoading = true;
    });

    final auth = ref.read(authProvider);
    final result = await _service.getCotizacion(id: id, token: auth.token!);

    if (result['success'] && mounted) {
      setState(() {
        _selectedCotizacion = Cotizacion.fromJson(result['data']);
        _isDetailLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isDetailLoading = false;
      });
      showToast(
        context,
        result['message'] ?? 'Error al cargar detalles',
        bgColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cotizacionHistorialProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text(
          'Historial de Cotizaciones',
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
              final auth = ref.read(authProvider);
              ref
                  .read(cotizacionHistorialProvider.notifier)
                  .fetchHistorial(auth.token!);
              setState(() {
                _selectedCotizacion = null;
              });
            },
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
              ? Center(child: Text(state.error!))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IZQUIERDA: LISTA Y RESUMEN
                      Expanded(
                        flex: isTablet ? 4 : 1,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildDateFilters()),
                                const SizedBox(width: 8),
                                _buildEstadoDropdown(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildResumenTarjetas(state),
                            const SizedBox(height: 12),
                            _buildSearchBar(),
                            const SizedBox(height: 12),
                            Expanded(
                              child: state.historial.isEmpty && !state.isLoading
                                  ? const Center(
                                      child: Text('No hay cotizaciones'),
                                    )
                                  : ListView.separated(
                                      controller: _scrollController,
                                      itemCount:
                                          state.historial.length +
                                          (state.isFetchingMore ? 1 : 0),
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        if (index == state.historial.length) {
                                          return const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          );
                                        }
                                        final cotizacion =
                                            state.historial[index];
                                        final isSelected =
                                            _selectedCotizacion?.id ==
                                            cotizacion.id;

                                        return CotizacionListItem(
                                          cotizacion: cotizacion,
                                          isSelected: isSelected,
                                          onTap: () => _loadCotizacionDetalle(
                                            cotizacion.id.toString(),
                                          ),
                                          onPdfTap: () => _verPdf(cotizacion),
                                          onEstadoChange: (val) =>
                                              _cambiarEstado(
                                                cotizacion.id.toString(),
                                                val,
                                              ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),

                      if (isTablet) const SizedBox(width: 16),

                      // DERECHA: DETALLES (PANEL)
                      if (isTablet)
                        Expanded(
                          flex: 5,
                          child: CotizacionDetallePanel(
                            cotizacion: _selectedCotizacion,
                            isLoading: _isDetailLoading,
                            onPdfTap: () => _verPdf(_selectedCotizacion!),
                          ),
                        ),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildResumenTarjetas(CotizacionHistorialState state) {
    final totales = state.totales;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Cotizado Aprobado',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      FormatterNumber.formatCurrency(totales['total'] ?? 0),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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

  Widget _buildDateFilters() {
    final filters = [
      'Todos',
      'Hoy',
      'Últimos 7 días',
      'Últimos 30 días',
      'Este mes',
      'Mes pasado',
      'Este año',
      'Personalizado',
    ];

    return CustomFilterDropdown<String>(
      value: _selectedDateFilter,
      items: filters
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      onChanged: (val) {
        if (val != null && val != 'Personalizado') {
          _applyDateFilter(val);
        }
      },
    );
  }

  void _applyDateFilter(String filterLabel) {
    setState(() {
      _selectedDateFilter = filterLabel;
      _selectedCotizacion = null;
    });

    final auth = ref.read(authProvider);
    final now = DateTime.now();
    Map<String, String> newFilters = {};

    switch (filterLabel) {
      case 'Hoy':
        final todayStr = now.toIso8601String().split('T')[0];
        newFilters = {'fecha_desde': todayStr, 'fecha_hasta': todayStr};
        break;
      case 'Últimos 7 días':
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        newFilters = {
          'fecha_desde': sevenDaysAgo.toIso8601String().split('T')[0],
          'fecha_hasta': now.toIso8601String().split('T')[0],
        };
        break;
      case 'Últimos 30 días':
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        newFilters = {
          'fecha_desde': thirtyDaysAgo.toIso8601String().split('T')[0],
          'fecha_hasta': now.toIso8601String().split('T')[0],
        };
        break;
      case 'Este mes':
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        newFilters = {
          'fecha_desde': firstDayOfMonth.toIso8601String().split('T')[0],
          'fecha_hasta': now.toIso8601String().split('T')[0],
        };
        break;
      case 'Mes pasado':
        final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(
          now.year,
          now.month,
          0,
        ); // Day 0 is last day of previous month
        newFilters = {
          'fecha_desde': firstDayOfLastMonth.toIso8601String().split('T')[0],
          'fecha_hasta': lastDayOfLastMonth.toIso8601String().split('T')[0],
        };
        break;
      case 'Este año':
        final firstDayOfYear = DateTime(now.year, 1, 1);
        newFilters = {
          'fecha_desde': firstDayOfYear.toIso8601String().split('T')[0],
          'fecha_hasta': now.toIso8601String().split('T')[0],
        };
        break;
      case 'Todos':
      default:
        // Vacío para limpiar los filtros de fecha
        break;
    }

    if (filterLabel == 'Todos') {
      // Limpiamos totalmente o solo las fechas?
      // Es mejor actualizar solo pasando nulos o recargando con fetchHistorial y filtros vacíos,
      // pero nuestro updateFilters hace merge. Usaremos un replace.
      ref.read(cotizacionHistorialProvider.notifier).clearFilters(auth.token!);
    } else {
      // Actualizamos los filtros de fecha y sobreescribimos los anteriores.
      ref.read(cotizacionHistorialProvider.notifier).updateFilters(
        auth.token!,
        {...newFilters, 'estado': _selectedEstadoFilter},
        replace: true,
      );
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
        _selectedCotizacion = null;
      });
      final auth = ref.read(authProvider);
      ref.read(cotizacionHistorialProvider.notifier).updateFilters(
        auth.token!,
        {'search': query},
      );
    });
  }

  Widget _buildEstadoDropdown() {
    return CustomFilterDropdown<String>(
      value: _selectedEstadoFilter,
      items: const [
        DropdownMenuItem(value: 'todos', child: Text('Estados: Todos')),
        DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')),
        DropdownMenuItem(value: 'aprobado', child: Text('Aprobadas')),
        DropdownMenuItem(value: 'cancelado', child: Text('Canceladas')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedEstadoFilter = val;
            _selectedCotizacion = null;
          });
          final auth = ref.read(authProvider);
          ref.read(cotizacionHistorialProvider.notifier).updateFilters(
            auth.token!,
            {'estado': val},
          );
        }
      },
    );
  }

  void _applyCustomDateFilter(DateTime start, DateTime end) {
    setState(() {
      _selectedDateFilter = 'Personalizado';
      _selectedCotizacion = null;
    });
    final auth = ref.read(authProvider);
    final newFilters = {
      'fecha_desde': start.toIso8601String().split('T')[0],
      'fecha_hasta': end.toIso8601String().split('T')[0],
    };
    ref
        .read(cotizacionHistorialProvider.notifier)
        .updateFilters(auth.token!, newFilters, replace: true);
  }

  List<Cotizacion> _getFilteredList(List<Cotizacion> historial) {
    if (_searchQuery.isEmpty) return historial;
    final query = TextNormalizer.normalizar(_searchQuery.toLowerCase());
    return historial.where((c) {
      final idMatch = c.id.toString().contains(query);
      final nombreMatch = TextNormalizer.normalizar(
        c.cliente?.nombre?.toLowerCase() ?? "",
      ).contains(query);
      return idMatch || nombreMatch;
    }).toList();
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar por # de cotización o cliente...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        CustomDateRangePicker(
          isPersonalizado: _selectedDateFilter == 'Personalizado',
          onDateRangeSelected: _applyCustomDateFilter,
        ),
      ],
    );
  }
}
