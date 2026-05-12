import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/utils/helpers.dart';
import '../../palletes/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../models/empleado_model.dart';
import '../providers/nomina_provider.dart';

class EmpleadoFormDialog extends ConsumerStatefulWidget {
  final EmpleadoModel? empleado;
  const EmpleadoFormDialog({super.key, this.empleado});

  @override
  ConsumerState<EmpleadoFormDialog> createState() => _EmpleadoFormDialogState();
}

class _EmpleadoFormDialogState extends ConsumerState<EmpleadoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _cedulaController;
  late TextEditingController _salarioController;
  late TextEditingController _cargoController;
  late TextEditingController _turnoController;
  late DateTime _fechaIngreso;
  String _tipoNomina = 'Mensual';
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.empleado?.nombre);
    _cedulaController = TextEditingController(text: widget.empleado?.cedula);
    _salarioController = TextEditingController(
      text: widget.empleado?.salarioBase.toString() ?? '0',
    );
    _cargoController = TextEditingController(text: widget.empleado?.cargo);
    _turnoController = TextEditingController(text: widget.empleado?.turno);
    _fechaIngreso = widget.empleado?.fechaIngreso ?? DateTime.now();
    _tipoNomina = widget.empleado?.tipoNomina ?? 'Mensual';
    _activo = widget.empleado?.activo ?? true;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final nuevoEmpleado = EmpleadoModel(
      id: widget.empleado?.id,
      nombre: _nombreController.text.trim(),
      cedula: _cedulaController.text.trim(),
      salarioBase: double.tryParse(_salarioController.text) ?? 0,
      tipoNomina: _tipoNomina,
      turno: _turnoController.text.trim(),
      fechaIngreso: _fechaIngreso,
      cargo: _cargoController.text.trim(),
      activo: _activo,
    );

    final success = await ref.read(nominaProvider.notifier).saveEmpleado(nuevoEmpleado);

    if (mounted) {
      if (success) {
        showToast(context, "Empleado guardado con éxito", bgColor: Colors.green);
        Navigator.pop(context, true);
      } else {
        showToast(context, "Error al guardar empleado", bgColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.empleado == null ? 'Nuevo Empleado' : 'Editar Empleado',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                const Text(
                  'INFORMACIÓN PERSONAL',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 11),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _nombreController,
                        label: 'Nombre Completo',
                        hintText: 'Ej: Juan Pérez',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomTextField(
                        controller: _cedulaController,
                        label: 'Cédula / ID',
                        hintText: '000-0000000-0',
                        prefixIcon: Icons.badge_outlined,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'DATOS LABORALES Y PAGOS',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 11),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _salarioController,
                        label: 'Salario Base Mensual',
                        prefixIcon: Icons.monetization_on_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Frecuencia de Pago',
                        value: _tipoNomina,
                        items: ['Semanal', 'Quincenal', 'Mensual'],
                        onChanged: (v) => setState(() => _tipoNomina = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _cargoController,
                        label: 'Cargo',
                        hintText: 'Ej: Chef, Mesero',
                        prefixIcon: Icons.work_outline,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomTextField(
                        controller: _turnoController,
                        label: 'Turno de Trabajo',
                        hintText: 'Ej: Mañana, Tarde',
                        prefixIcon: Icons.access_time,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildDatePicker(),
                
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('Empleado Activo', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: _activo,
                      onChanged: (v) => setState(() => _activo = v),
                      activeColor: AppColors.success,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulOscuro,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.empleado == null ? 'REGISTRAR EMPLEADO' : 'ACTUALIZAR DATOS',
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
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
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _fechaIngreso,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _fechaIngreso = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fecha de Ingreso', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(formatFechaLatina(_fechaIngreso), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
