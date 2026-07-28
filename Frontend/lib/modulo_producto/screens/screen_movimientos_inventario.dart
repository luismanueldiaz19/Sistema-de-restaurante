import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_loading.dart';
import '../providers/inventario_provider.dart';
import 'nuevo_ajuste_dialog.dart';
import 'package:intl/intl.dart';

class ScreenMovimientosInventario extends ConsumerStatefulWidget {
  const ScreenMovimientosInventario({super.key});

  @override
  ConsumerState<ScreenMovimientosInventario> createState() => _ScreenMovimientosInventarioState();
}

class _ScreenMovimientosInventarioState extends ConsumerState<ScreenMovimientosInventario> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      ref.read(inventarioProvider.notifier).loadMovimientos(auth.token!);
    });
  }

  void _abrirNuevoAjuste() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NuevoAjusteDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventarioProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Historial de Ajustes de Inventario",
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _abrirNuevoAjuste,
              icon: const Icon(Icons.add),
              label: const Text("Nuevo Ajuste"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          )
        ],
      ),
      body: state.isLoading
          ? const Center(child: CustomLoading(text: "Cargando movimientos..."))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Aquí puedes ver el historial de ajustes manuales de stock y agregar nuevos ajustes sin afectar la contabilidad.",
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                          columns: const [
                            DataColumn2(label: Text("FECHA", style: TextStyle(fontWeight: FontWeight.bold)), fixedWidth: 150),
                            DataColumn2(label: Text("PRODUCTO", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn2(label: Text("TIPO", style: TextStyle(fontWeight: FontWeight.bold)), fixedWidth: 120),
                            DataColumn2(label: Text("CANTIDAD", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true, fixedWidth: 120),
                            DataColumn2(label: Text("MOTIVO", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: state.movimientos.map((m) {
                            final dateStr = m.fecha != null ? DateFormat('yyyy-MM-dd HH:mm').format(m.fecha!) : '--';
                            final isEntrada = m.tipo == 'ENTRADA';
                            
                            return DataRow2(
                              cells: [
                                DataCell(Text(dateStr, style: const TextStyle(color: Colors.blueGrey, fontSize: 13))),
                                DataCell(Text(m.producto?.nombre ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isEntrada ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m.tipo ?? '',
                                      style: TextStyle(
                                        color: isEntrada ? Colors.green : Colors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                ),
                                DataCell(Text(
                                  "${isEntrada ? '+' : '-'}${m.cantidad}", 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isEntrada ? Colors.green : Colors.red,
                                  )
                                )),
                                DataCell(Text(m.referencia ?? '')),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
