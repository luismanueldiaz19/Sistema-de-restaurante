import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../models/ingrediente.dart';
import '../providers/ingrediente_provider.dart';

class AddIngredienteDialog extends ConsumerStatefulWidget {
  final Ingrediente? ingrediente;
  const AddIngredienteDialog({super.key, this.ingrediente});

  @override
  ConsumerState<AddIngredienteDialog> createState() => _AddIngredienteDialogState();
}

class _AddIngredienteDialogState extends ConsumerState<AddIngredienteDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final nombreCtrl = TextEditingController();
  final unidadCtrl = TextEditingController(text: 'KG');
  final costoCtrl = TextEditingController(text: '0');
  final stockCtrl = TextEditingController(text: '0');

  bool get isEdit => widget.ingrediente != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final i = widget.ingrediente!;
      nombreCtrl.text = i.nombre;
      unidadCtrl.text = i.unidad ?? 'KG';
      costoCtrl.text = i.costoUnitario.toString();
      stockCtrl.text = i.stock.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Editar Ingrediente' : 'Nuevo Ingrediente',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulOscuro),
              ),
              const Divider(),
              const SizedBox(height: 16),
              CustomTextField(
                controller: nombreCtrl,
                label: 'Nombre del Ingrediente',
                hintText: 'Ej: Tomate, Harina, Carne Res',
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: unidadCtrl,
                      label: 'Unidad',
                      hintText: 'KG, LB, LT, UND',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: CustomTextField(
                      controller: costoCtrl,
                      label: 'Costo Unitario',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: stockCtrl,
                label: 'Stock Actual (Materia Prima)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulOscuro,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEdit ? 'Actualizar' : 'Crear Ingrediente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final provider = ref.read(ingredienteProvider.notifier);

    final data = {
      "nombre": nombreCtrl.text.trim(),
      "unidad": unidadCtrl.text.trim().toUpperCase(),
      "costo_unitario": double.tryParse(costoCtrl.text) ?? 0,
      "stock": double.tryParse(stockCtrl.text) ?? 0,
    };

    bool success;
    if (isEdit) {
      success = await provider.updateIngrediente(widget.ingrediente!.id.toString(), data, auth.token!);
    } else {
      success = await provider.createIngrediente(data, auth.token!);
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }
}
