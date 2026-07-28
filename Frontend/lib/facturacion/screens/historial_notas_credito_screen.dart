import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/nota_credito_model.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../providers/notas_credito_provider.dart';
import 'widgets/nota_credito_list_item.dart';
import 'widgets/nota_credito_detalle_panel.dart';

class HistorialNotasCreditoScreen extends ConsumerStatefulWidget {
  const HistorialNotasCreditoScreen({super.key});

  @override
  ConsumerState<HistorialNotasCreditoScreen> createState() => _HistorialNotasCreditoScreenState();
}

class _HistorialNotasCreditoScreenState extends ConsumerState<HistorialNotasCreditoScreen> {
  NotaCreditoModel? _selectedNota;
  String _selectedDateFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      ref.read(notasCreditoProvider.notifier).fetchHistorial(auth.token!);
    });
  }

  Future<void> _verPdf(String id) async {
    final auth = ref.read(authProvider);
    final urlWithToken = Uri.parse("$hostName/api/notas-credito/$id/pdf?token=${auth.token}");
    if (await canLaunchUrl(urlWithToken)) {
      await launchUrl(urlWithToken, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) showToast(context, 'No se pudo abrir el PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notasCreditoProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text(
          'Notas de Crédito',
          style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              final auth = ref.read(authProvider);
              ref.read(notasCreditoProvider.notifier).fetchHistorial(auth.token!);
              setState(() {
                _selectedNota = null;
              });
            },
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 800;

          return state.isLoading && state.historial.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : state.error != null
                  ? Center(child: Text(state.error!))
                  : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      ? const Center(child: Text('No hay notas de crédito'))
                                      : ListView.separated(
                                          itemCount: state.historial.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final nota = state.historial[index];
                                            final isSelected = _selectedNota?.id == nota.id;

                                            return NotaCreditoListItem(
                                              nota: nota,
                                              isSelected: isSelected,
                                              onTap: () {
                                                setState(() {
                                                  _selectedNota = nota;
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

                          if (isTablet)
                            Expanded(
                              flex: 5,
                              child: NotaCreditoDetallePanel(
                                nota: _selectedNota,
                                isLoading: false,
                                onPdfTap: () {
                                  if (_selectedNota != null) {
                                    _verPdf(_selectedNota!.id.toString());
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    );
        },
      ),
    );
  }

  Widget _buildResumenTarjetas(NotasCreditoState state) {
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
                  color: Colors.red.withValues(alpha: 0.1),
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
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_return, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total en Notas de Crédito', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
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
      _selectedNota = null;
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
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
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
      default:
        newFilters = {};
    }

    ref.read(notasCreditoProvider.notifier).updateFilters(auth.token!, newFilters, replace: true);
  }
}
