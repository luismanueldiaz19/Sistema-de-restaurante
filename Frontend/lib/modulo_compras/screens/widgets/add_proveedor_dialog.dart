import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../models/proveedor.dart';
import '../../providers/proveedores_provider.dart';
import '../../../../utils/helpers.dart'; // Para showToast si es necesario

class AddProveedorDialog extends ConsumerStatefulWidget {
  final Proveedor? proveedor;

  const AddProveedorDialog({super.key, this.proveedor});

  @override
  ConsumerState<AddProveedorDialog> createState() => _AddProveedorDialogState();
}

class _AddProveedorDialogState extends ConsumerState<AddProveedorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nombreCtrl;
  late final TextEditingController rncCtrl;
  late final TextEditingController telefonoCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController direccionCtrl;

  bool get isEdit => widget.proveedor != null;
  bool esInformal = false;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.proveedor?.nombre ?? '');
    rncCtrl = TextEditingController(text: widget.proveedor?.rnc ?? '');
    telefonoCtrl = TextEditingController(text: widget.proveedor?.telefono ?? '');
    emailCtrl = TextEditingController(text: widget.proveedor?.email ?? '');
    direccionCtrl = TextEditingController(text: widget.proveedor?.direccion ?? '');
    esInformal = widget.proveedor?.esInformal ?? false;
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    rncCtrl.dispose();
    telefonoCtrl.dispose();
    emailCtrl.dispose();
    direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (nombreCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }

    final Map<String, dynamic> data = {
      'nombre': nombreCtrl.text,
      'rnc': rncCtrl.text,
      'telefono': telefonoCtrl.text,
      'email': emailCtrl.text,
      'direccion': direccionCtrl.text,
      'es_informal': esInformal,
    };

    bool success;
    if (isEdit) {
      success = await ref
          .read(proveedoresProvider.notifier)
          .updateProveedor(widget.proveedor!.id, data);
    } else {
      success = await ref
          .read(proveedoresProvider.notifier)
          .createProveedor(data);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Proveedor actualizado' : 'Proveedor creado',
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Wait for provider to update and then close dialog
      // If we are creating from a search dialog, we might want to return the newly created provider,
      // but the API createProveedor returns bool, not the object right now.
      // We will just pop true and let the caller refresh.
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al guardar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(proveedoresProvider).isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 ENCABEZADO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Editar Proveedor' : 'Nuevo Proveedor',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingrese los datos del proveedor para gestionar compras y cuentas por pagar.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // 🔹 CAMPOS DEL FORMULARIO
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: nombreCtrl,
                        label: 'Nombre o Razón Social (*)',
                        prefixIcon: Icons.business,
                        validator: (value) =>
                            value!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: CustomTextField(
                        controller: rncCtrl,
                        label: 'RNC (Opcional)',
                        prefixIcon: Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: telefonoCtrl,
                        label: 'Teléfono (Opcional)',
                        prefixIcon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: emailCtrl,
                        label: 'Email (Opcional)',
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: direccionCtrl,
                  label: 'Dirección Física (Opcional)',
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Proveedor Informal (Sin NCF)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Se retendrá el 100% del ITBIS y se generará un Comprobante de Compras E41.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: esInformal,
                    activeColor: Colors.orange,
                    onChanged: (val) {
                      setState(() {
                        esInformal = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // 🔹 BOTONES
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        isEdit ? 'ACTUALIZAR PROVEEDOR' : 'CREAR PROVEEDOR',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
