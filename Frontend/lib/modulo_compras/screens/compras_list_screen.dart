import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
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
  bool _isExportingPdf = false;
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

  Future<void> _exportarPdfReporte() async {
    setState(() => _isExportingPdf = true);
    try {
      final notifier = ref.read(comprasProvider.notifier);
      final pdfUrlPath = await notifier.obtenerPdfReporteUrl();

      if (pdfUrlPath != null && pdfUrlPath.isNotEmpty) {
        final urlToLaunch = Uri.parse('$hostName$pdfUrlPath');
        if (await canLaunchUrl(urlToLaunch)) {
          await launchUrl(urlToLaunch, mode: LaunchMode.externalApplication);
        } else if (mounted) {
          showToast(context, 'No se pudo abrir el PDF', bgColor: Colors.orange);
        }
      } else if (mounted) {
        showToast(
          context,
          'No se pudo generar el reporte en PDF',
          bgColor: Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Error al exportar: $e', bgColor: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
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
          // Botón Exportar PDF con los filtros aplicados
          SizedBox(
            height: 34,
            child: OutlinedButton.icon(
              onPressed: _isExportingPdf ? null : _exportarPdfReporte,
              icon: _isExportingPdf
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
              label: const Text(
                'Reporte PDF',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                            const SizedBox(height: 8),
                            _buildResumenTarjetas(state),
                            const SizedBox(height: 10),
                            Expanded(
                              child: state.compras.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No hay compras registradas.',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    )
                                  : ListView.separated(
                                      controller: _scrollController,
                                      itemCount:
                                          state.compras.length +
                                          (state.hasMore ? 1 : 0),
                                      separatorBuilder: (_, index) =>
                                          const SizedBox(height: 8),
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

                      if (isTablet) const SizedBox(width: 16),

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
    final hasPendiente = state.totales.totalPendiente > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Total General
          Expanded(
            child: _buildMetricItem(
              icon: Icons.receipt_long_outlined,
              iconColor: AppColors.primary,
              bgColor: AppColors.primary.withValues(alpha: 0.1),
              label: 'Total General',
              value: FormatterNumber.formatCurrency(
                state.totales.totalGeneral,
              ),
              valueColor: AppColors.secondary,
            ),
          ),
          Container(
            height: 26,
            width: 1,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          // Pagado
          Expanded(
            child: _buildMetricItem(
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.success,
              bgColor: AppColors.success.withValues(alpha: 0.1),
              label: 'Pagado',
              value: FormatterNumber.formatCurrency(
                state.totales.totalPagado,
              ),
              valueColor: AppColors.success,
            ),
          ),
          if (hasPendiente) ...[
            Container(
              height: 26,
              width: 1,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            // Pendiente
            Expanded(
              child: _buildMetricItem(
                icon: Icons.pending_actions_outlined,
                iconColor: Colors.orange.shade700,
                bgColor: Colors.orange.shade50,
                label: 'Pendiente',
                value: FormatterNumber.formatCurrency(
                  state.totales.totalPendiente,
                ),
                valueColor: Colors.orange.shade800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
