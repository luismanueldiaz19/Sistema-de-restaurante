import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/utils/helpers.dart';
import '../../palletes/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../models/nomina_detalle_model.dart';
import '../models/nomina_model.dart';
import '../providers/nomina_provider.dart';
import '../services/nomina_calculator.dart';

class AddNominaDialog extends ConsumerStatefulWidget {
  const AddNominaDialog({super.key});

  @override
  ConsumerState<AddNominaDialog> createState() => _AddNominaDialogState();
}

class _AddNominaDialogState extends ConsumerState<AddNominaDialog> {
  final TextEditingController _periodoController = TextEditingController(
    text:
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}",
  );

  String _tipoNomina = 'Mensual';
  List<NominaDetalleModel> _calculos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarYCalcular();
    });
  }

  Future<void> _cargarYCalcular() async {
    await ref.read(nominaProvider.notifier).fetchEmpleados();
    final allEmpleados = ref.read(nominaProvider).empleados;

    final empleados = allEmpleados
        .where((e) => e.tipoNomina == _tipoNomina)
        .toList();

    setState(() {
      _calculos = empleados.map((e) {
        final res = NominaCalculator.calculateAll(
          e.salarioBase,
          frecuencia: _tipoNomina,
        );
        return NominaDetalleModel(
          empleadoId: e.id!,
          nombreEmpleado: e.nombre,
          salarioBruto: res['salarioBruto']!,
          horasExtras: 0,
          incentivos: 0,
          feriados: 0,
          afpEmpleado: res['afp']!,
          sfsEmpleado: res['sfs']!,
          isrRetencion: res['isr']!,
          otrosDescuentos: 0.0,
          salarioNeto: res['salarioNeto']!,
        );
      }).toList();
    });
  }

  void _updateCalculo(
    int index, {
    double? extras,
    double? incentivos,
    double? feriados,
  }) {
    final calc = _calculos[index];
    final emp = ref
        .read(nominaProvider)
        .empleados
        .firstWhere((e) => e.id == calc.empleadoId);

    final res = NominaCalculator.calculateAll(
      emp.salarioBase,
      frecuencia: _tipoNomina,
      horasExtras: extras ?? calc.horasExtras,
      incentivos: incentivos ?? calc.incentivos,
      feriados: feriados ?? calc.feriados,
    );

    setState(() {
      _calculos[index] = NominaDetalleModel(
        empleadoId: calc.empleadoId,
        nombreEmpleado: calc.nombreEmpleado,
        salarioBruto: res['salarioBruto']!,
        horasExtras: extras ?? calc.horasExtras,
        incentivos: incentivos ?? calc.incentivos,
        feriados: feriados ?? calc.feriados,
        afpEmpleado: res['afp']!,
        sfsEmpleado: res['sfs']!,
        isrRetencion: res['isr']!,
        otrosDescuentos: calc.otrosDescuentos,
        salarioNeto: res['salarioNeto']!,
      );
    });
  }

  void _guardarNomina() async {
    if (_calculos.isEmpty) return;

    final success = await ref
        .read(nominaProvider.notifier)
        .createNomina(
          NominaModel(
            periodo: _periodoController.text,
            fechaCreacion: DateTime.now(),
            detalles: _calculos,
          ),
        );

    if (mounted) {
      if (success) {
        showToast(context, "Nómina generada con éxito", bgColor: Colors.green);
        Navigator.pop(context, true);
      } else {
        showToast(context, "Error al guardar nómina", bgColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nominaProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1200, // Un poco más ancho para las nuevas columnas
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 32),
            _buildTopBar(),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _calculos.isEmpty
                    ? const Center(
                        child: Text("No hay empleados activos para procesar"),
                      )
                    : _buildDetalleTable(),
              ),
            ),
            const SizedBox(height: 24),
            _buildFooterSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generar Nómina y Novedades',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            Text(
              'Ingresa horas extras o incentivos antes de procesar el pago',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        SizedBox(
          width: 180,
          child: CustomTextField(
            controller: _periodoController,
            label: 'Periodo',
            hintText: 'AAAA-MM',
            prefixIcon: Icons.calendar_month,
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 200,
          child: _buildDropdown(
            label: 'Frecuencia',
            value: _tipoNomina,
            items: ['Semanal', 'Quincenal', 'Mensual'],
            onChanged: (v) {
              setState(() => _tipoNomina = v!);
              _cargarYCalcular();
            },
          ),
        ),
        const Spacer(),
        const Text(
          '💡 Los cambios se recalculan automáticamente',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleTable() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.grey.shade100),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
            columnSpacing: 25,
            columns: const [
              DataColumn(
                label: Text(
                  'EMPLEADO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'BRUTO BASE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'H. EXTRAS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'INCENTIVOS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'AFP (2.87%)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'SFS (3.04%)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ISR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'NETO FINAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
            rows: _calculos.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      d.nombreEmpleado,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      formatCurrency(
                        d.salarioBruto -
                            d.horasExtras -
                            d.incentivos -
                            d.feriados,
                      ),
                    ),
                  ),
                  DataCell(
                    _buildInputCell(
                      d.horasExtras,
                      (v) => _updateCalculo(index, extras: v),
                    ),
                  ),
                  DataCell(
                    _buildInputCell(
                      d.incentivos,
                      (v) => _updateCalculo(index, incentivos: v),
                    ),
                  ),
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
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCell(double value, Function(double) onChanged) {
    return SizedBox(
      width: 100,
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          prefixText: 'RD\$ ',
        ),
        style: const TextStyle(fontSize: 13),
        onChanged: (v) {
          final val = double.tryParse(v) ?? 0.0;
          onChanged(val);
        },
      ),
    );
  }

  Widget _buildFooterSummary() {
    double totalNeto = _calculos.fold(0, (a, b) => a + b.salarioNeto);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL NETO A PAGAR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                formatCurrency(totalNeto),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.azulOscuro,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _guardarNomina,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'CONFIRMAR Y PROCESAR NÓMINA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
