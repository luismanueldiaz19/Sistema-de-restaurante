import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../models/cotizacion_model.dart';
import '../providers/cotizacion_historial_provider.dart';
import '../services/cotizacion_service.dart';
import '../../utils/helpers.dart';
import '../../palletes/app_colors.dart';
import '../../utils/constants.dart';
import 'widgets/cotizacion_list_item.dart';
import 'widgets/cotizacion_detalle_panel.dart';

class HistorialCotizacionesScreen extends ConsumerStatefulWidget {
  const HistorialCotizacionesScreen({super.key});

  @override
  ConsumerState<HistorialCotizacionesScreen> createState() => _HistorialCotizacionesScreenState();
}

class _HistorialCotizacionesScreenState extends ConsumerState<HistorialCotizacionesScreen> {
  Cotizacion? _selectedCotizacion;
  bool _isDetailLoading = false;
  String _selectedDateFilter = 'Todos'; // Estado para el chip seleccionado
  final CotizacionService _service = CotizacionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      ref.read(cotizacionHistorialProvider.notifier).fetchHistorial(auth.token!);
    });
  }

  Future<void> _cambiarEstado(String id, String estado) async {
    final auth = ref.read(authProvider);
    final success = await ref.read(cotizacionHistorialProvider.notifier).updateEstado(auth.token!, id, estado);
    if (success && mounted) {
      showToast(context, 'Estado actualizado a $estado', bgColor: Colors.green);
      if (_selectedCotizacion?.id.toString() == id) {
        _loadCotizacionDetalle(id); // Reload details if selected
      }
    } else if (mounted) {
      showToast(context, 'Error al actualizar', bgColor: Colors.red);
    }
  }

  Future<void> _verPdf(String id) async {
    final urlWithToken = Uri.parse("$hostName/api/cotizaciones/$id/pdf");
    if (await canLaunchUrl(urlWithToken)) {
      await launchUrl(urlWithToken, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) showToast(context, 'No se pudo abrir el PDF');
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
      showToast(context, result['message'] ?? 'Error al cargar detalles', bgColor: Colors.red);
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
          style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              final auth = ref.read(authProvider);
              ref.read(cotizacionHistorialProvider.notifier).fetchHistorial(auth.token!);
              setState(() {
                _selectedCotizacion = null;
              });
            },
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 800;

          return state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : state.error != null
                  ? Center(child: Text(state.error!))
                  : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // IZQUIERDA: LISTA Y RESUMEN
                          Expanded(
                            flex: isTablet ? 4 : 1,
                            child: Column(
                              children: [
                                _buildDateFilters(),
                                const SizedBox(height: 16),
                                _buildResumenTarjetas(state),
                                const SizedBox(height: 24),
                                Expanded(
                                  child: state.historial.isEmpty
                                      ? const Center(child: Text('No hay cotizaciones'))
                                      : ListView.separated(
                                          itemCount: state.historial.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final cotizacion = state.historial[index];
                                            final isSelected = _selectedCotizacion?.id == cotizacion.id;

                                            return CotizacionListItem(
                                              cotizacion: cotizacion,
                                              isSelected: isSelected,
                                              onTap: () => _loadCotizacionDetalle(cotizacion.id.toString()),
                                              onPdfTap: () => _verPdf(cotizacion.id.toString()),
                                              onEstadoChange: (val) => _cambiarEstado(cotizacion.id.toString(), val),
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
                              child: CotizacionDetallePanel(
                                cotizacion: _selectedCotizacion,
                                isLoading: _isDetailLoading,
                                onPdfTap: () => _verPdf(_selectedCotizacion!.id.toString()),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.monetization_on, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Cotizado Aprobado', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(totales['total'] ?? 0),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.secondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDateFilters() {
    final filters = [
      'Todos',
      'Hoy',
      'Últimos 7 días',
      'Este mes',
      'Mes pasado',
      'Este año'
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = filters[index];
          final isSelected = _selectedDateFilter == label;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (selected) {
              if (selected) {
                _applyDateFilter(label);
              }
            },
          );
        },
      ),
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
      case 'Este mes':
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        newFilters = {
          'fecha_desde': firstDayOfMonth.toIso8601String().split('T')[0],
          'fecha_hasta': now.toIso8601String().split('T')[0],
        };
        break;
      case 'Mes pasado':
        final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0); // Day 0 is last day of previous month
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
      ref.read(cotizacionHistorialProvider.notifier).updateFilters(auth.token!, newFilters, replace: true);
    }
  }
}
