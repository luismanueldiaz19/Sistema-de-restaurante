import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../providers/reportes_contables_provider.dart';
import '../../utils/helpers.dart';

class BalanceGeneralScreen extends ConsumerStatefulWidget {
  const BalanceGeneralScreen({super.key});

  @override
  ConsumerState<BalanceGeneralScreen> createState() => _BalanceGeneralScreenState();
}

class _BalanceGeneralScreenState extends ConsumerState<BalanceGeneralScreen> {
  DateTime _fechaHasta = DateTime.now();

  void _seleccionarFecha(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaHasta,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _fechaHasta = date;
      });
    }
  }

  Widget _buildNode(Map<String, dynamic> nodo, {int depth = 0}) {
    final bool esDetalle = nodo['es_detalle'] ?? false;
    final double balance = double.tryParse(nodo['balance'].toString()) ?? 0;
    
    // Si no es detalle y balance es 0, no lo mostramos a menos que tenga hijos con data
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
    final asyncData = ref.watch(balanceGeneralProvider(_fechaHasta.toIso8601String().split('T')[0]));

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Balance General', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.secondary),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => _seleccionarFecha(context),
              icon: const Icon(Icons.date_range),
              label: Text("Al: ${_fechaHasta.toIso8601String().split('T')[0]}"),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          )
        ],
      ),
      body: asyncData.when(
        data: (data) {
          final activos = data['activos'] as List<dynamic>;
          final pasivos = data['pasivos'] as List<dynamic>;
          final capital = data['capital'] as List<dynamic>;
          final totales = data['totales'];
          final utilidad = data['utilidad_ejercicio'];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSection('ACTIVOS', activos, double.tryParse(totales['activo'].toString()) ?? 0),
              _buildSection('PASIVOS', pasivos, double.tryParse(totales['pasivo'].toString()) ?? 0),
              
              // CAPITAL (incluye Utilidad del Ejercicio)
              Container(
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
                          const Text('CAPITAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          Text(
                            formatCurrency((double.tryParse(totales['capital'].toString()) ?? 0) + (double.tryParse(utilidad.toString()) ?? 0)), 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          ...capital.map((n) => _buildNode(n)),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_right, size: 18, color: Colors.grey.shade400),
                                    const SizedBox(width: 8),
                                    const Text("Utilidad del Ejercicio", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                  ],
                                ),
                                Text(
                                  formatCurrency(double.tryParse(utilidad.toString()) ?? 0),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // TOTAL PASIVO Y CAPITAL
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade900]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL PASIVO Y CAPITAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text(
                      formatCurrency(double.tryParse(totales['pasivo_y_capital'].toString()) ?? 0), 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)
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
    );
  }
}
