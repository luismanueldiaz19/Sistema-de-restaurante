import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../providers/reportes_contables_provider.dart';
import '../../utils/helpers.dart';

class EstadoResultadosScreen extends ConsumerStatefulWidget {
  const EstadoResultadosScreen({super.key});

  @override
  ConsumerState<EstadoResultadosScreen> createState() => _EstadoResultadosScreenState();
}

class _EstadoResultadosScreenState extends ConsumerState<EstadoResultadosScreen> {
  DateTime _fechaDesde = DateTime(DateTime.now().year, 1, 1);
  DateTime _fechaHasta = DateTime.now();

  void _seleccionarFecha(BuildContext context, bool isDesde) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isDesde ? _fechaDesde : _fechaHasta,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        if (isDesde) _fechaDesde = date;
        else _fechaHasta = date;
      });
    }
  }

  Widget _buildNode(Map<String, dynamic> nodo, {int depth = 0}) {
    final bool esDetalle = nodo['es_detalle'] ?? false;
    final double balance = double.tryParse(nodo['balance'].toString()) ?? 0;
    
    if (balance == 0 && (nodo['hijos'] == null || (nodo['hijos'] as List).isEmpty)) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 24.0, top: 8, bottom: 8, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (!esDetalle) Icon(Icons.folder_open, size: 18, color: Colors.grey.shade600),
                    if (esDetalle) Icon(Icons.arrow_right, size: 18, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${nodo['codigo']} - ${nodo['nombre']}",
                        style: TextStyle(
                          fontWeight: esDetalle ? FontWeight.normal : FontWeight.bold,
                          color: esDetalle ? Colors.black87 : AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatCurrency(balance),
                style: TextStyle(
                  fontWeight: esDetalle ? FontWeight.normal : FontWeight.bold,
                  color: balance < 0 ? Colors.red : (esDetalle ? Colors.black87 : AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
        if (!esDetalle && nodo['hijos'] != null)
          ...((nodo['hijos'] as List).map((hijo) => _buildNode(hijo, depth: depth + 1))),
        if (!esDetalle && depth == 0)
          const Divider(height: 1),
      ],
    );
  }

  Widget _buildSection(String title, List<dynamic> nodos, double total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                Text(formatCurrency(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: nodos.map((n) => _buildNode(n)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paramStr = "${_fechaDesde.toIso8601String().split('T')[0]}|${_fechaHasta.toIso8601String().split('T')[0]}";
    final asyncData = ref.watch(estadoResultadosProvider(paramStr));

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Estado de Resultados', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.secondary),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _seleccionarFecha(context, true),
                  icon: const Icon(Icons.date_range),
                  label: Text("Desde: ${_fechaDesde.toIso8601String().split('T')[0]}"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.light, foregroundColor: AppColors.secondary),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _seleccionarFecha(context, false),
                  icon: const Icon(Icons.date_range),
                  label: Text("Hasta: ${_fechaHasta.toIso8601String().split('T')[0]}"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncData.when(
              data: (data) {
                final ingresos = data['ingresos'] as List<dynamic>;
                final costos = data['costos'] as List<dynamic>;
                final gastos = data['gastos'] as List<dynamic>;
                final totales = data['totales'];

                final utilidadBruta = double.tryParse(totales['utilidad_bruta'].toString()) ?? 0;
                final utilidadNeta = double.tryParse(totales['utilidad_neta'].toString()) ?? 0;

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSection('INGRESOS', ingresos, double.tryParse(totales['ingresos'].toString()) ?? 0),
                    _buildSection('COSTOS', costos, double.tryParse(totales['costos'].toString()) ?? 0),
                    
                    // UTILIDAD BRUTA
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('UTILIDAD BRUTA (Ingresos - Costos)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          Text(formatCurrency(utilidadBruta), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        ],
                      ),
                    ),

                    _buildSection('GASTOS', gastos, double.tryParse(totales['gastos'].toString()) ?? 0),

                    // UTILIDAD NETA
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: utilidadNeta >= 0 
                            ? [Colors.green.shade700, Colors.green.shade900]
                            : [Colors.red.shade700, Colors.red.shade900]
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: (utilidadNeta >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                        ]
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            utilidadNeta >= 0 ? 'UTILIDAD NETA' : 'PÉRDIDA NETA', 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)
                          ),
                          Text(
                            formatCurrency(utilidadNeta), 
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}
