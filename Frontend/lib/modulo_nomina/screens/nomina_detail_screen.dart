import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/nomina_model.dart';
import '../providers/nomina_provider.dart';
import '../services/nomina_pdf_service.dart';

class NominaDetailScreen extends ConsumerWidget {
  final NominaModel nomina;

  const NominaDetailScreen({super.key, required this.nomina});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(nominaProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('Nómina ${nomina.periodo}'),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => showToast(context, "Generando reporte..."),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: const Text('PDF', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // 📋 Tabla de Desglose (Ocupa el espacio disponible)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Desglose por Empleado',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFullWidthTable(context),
                ],
              ),
            ),
          ),

          // 💰 Resumen de Totales al Final
          _buildBottomSummary(context, ref, isLoading),
        ],
      ),
    );
  }

  Widget _buildFullWidthTable(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.grey.shade100),
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 15,
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(
              label: Expanded(
                child: Text(
                  'EMPLEADO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'BRUTO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'AFP (2.87%)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'SFS (3.04%)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text('ISR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'NETO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'ACCIONES',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: nomina.detalles.map((d) {
            // Sumamos AFP + SFS para mostrarlo como "TSS" (simplificado para el ancho)
            double tssTotal = d.afpEmpleado + d.sfsEmpleado;
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    d.nombreEmpleado,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(Text(formatCurrency(d.salarioBruto))),
                DataCell(
                  Text(
                    formatCurrency(d.afpEmpleado),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                DataCell(
                  Text(
                    formatCurrency(d.sfsEmpleado),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                DataCell(
                  Text(
                    formatCurrency(d.isrRetencion),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                DataCell(
                  Text(
                    formatCurrency(d.salarioNeto),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(
                      Icons.print_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    tooltip: 'Imprimir Volante (Deshabilitado)',
                    onPressed: () {
                      // NominaPdfService.generateVolante(nomina, d);
                      print("Impresión deshabilitada");
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomSummary(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _FooterItem(
              label: 'TOTAL BRUTO',
              value: formatCurrency(nomina.totalBruto),
              color: Colors.blueGrey,
            ),
            const SizedBox(width: 20),
            _FooterItem(
              label: 'RETENCIONES',
              value: formatCurrency(nomina.totalRetenciones),
              color: Colors.red,
            ),
            const Spacer(),
            _FooterItem(
              label: 'NETO A PAGAR',
              value: formatCurrency(nomina.totalNeto),
              color: AppColors.success,
              isLarge: true,
            ),
            if (nomina.estado == 'Borrador') ...[
              const SizedBox(width: 30),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(nominaProvider.notifier)
                            .updateNominaStatus(nomina.id!, 'Pagado');
                        if (context.mounted && success) {
                          showToast(
                            context,
                            "Nómina confirmada y pagada",
                            bgColor: Colors.green,
                          );
                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulOscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'APROBAR Y PAGAR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FooterItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLarge;

  const _FooterItem({
    required this.label,
    required this.value,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 22 : 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
