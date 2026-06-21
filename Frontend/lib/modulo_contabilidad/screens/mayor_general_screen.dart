import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../providers/reportes_contables_provider.dart';
import '../../utils/helpers.dart';

class MayorGeneralScreen extends ConsumerStatefulWidget {
  const MayorGeneralScreen({super.key});

  @override
  ConsumerState<MayorGeneralScreen> createState() => _MayorGeneralScreenState();
}

class _MayorGeneralScreenState extends ConsumerState<MayorGeneralScreen> {
  DateTime _fechaDesde = DateTime(DateTime.now().year, 1, 1);
  DateTime _fechaHasta = DateTime.now();
  String _searchQuery = "";

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

  @override
  Widget build(BuildContext context) {
    final paramStr = "${_fechaDesde.toIso8601String().split('T')[0]}|${_fechaHasta.toIso8601String().split('T')[0]}";
    final asyncData = ref.watch(mayorGeneralProvider(paramStr));

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Mayor General', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.secondary),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Filtros
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar por código o nombre de cuenta...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _seleccionarFecha(context, true),
                    icon: const Icon(Icons.date_range),
                    label: Text("Desde: ${_fechaDesde.toIso8601String().split('T')[0]}"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.secondary),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _seleccionarFecha(context, false),
                    icon: const Icon(Icons.date_range),
                    label: Text("Hasta: ${_fechaHasta.toIso8601String().split('T')[0]}"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tabla de Resultados
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: asyncData.when(
                  data: (data) {
                    final filtered = data.where((c) {
                      return c['nombre'].toString().toLowerCase().contains(_searchQuery) ||
                             c['codigo'].toString().toLowerCase().contains(_searchQuery);
                    }).toList();

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        DataTable(
                          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                          dataRowMaxHeight: 60,
                          dataRowMinHeight: 60,
                          columns: const [
                            DataColumn(label: Text('CÓDIGO')),
                            DataColumn(label: Text('CUENTA')),
                            DataColumn(label: Text('TIPO')),
                            DataColumn(label: Text('DÉBITOS', textAlign: TextAlign.right)),
                            DataColumn(label: Text('CRÉDITOS', textAlign: TextAlign.right)),
                            DataColumn(label: Text('BALANCE', textAlign: TextAlign.right)),
                          ],
                          rows: filtered.map((c) {
                            return DataRow(cells: [
                              DataCell(Text(c['codigo'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(c['nombre'].toString())),
                              DataCell(Text(c['tipo'].toString())),
                              DataCell(Text(formatCurrency(double.tryParse(c['total_debito'].toString()) ?? 0))),
                              DataCell(Text(formatCurrency(double.tryParse(c['total_credito'].toString()) ?? 0))),
                              DataCell(Text(
                                formatCurrency(double.tryParse(c['balance'].toString()) ?? 0),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: (double.tryParse(c['balance'].toString()) ?? 0) < 0 ? Colors.red : Colors.green,
                                ),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
