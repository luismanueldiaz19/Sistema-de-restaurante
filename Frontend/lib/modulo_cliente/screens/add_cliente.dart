import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../utils/phone_input_formatter.dart';
import '../models/cliente.dart';
import '../providers/cliente_admin_provider.dart';

Future<bool?> showAddClienteDialog(
  BuildContext context, {
  Cliente? cliente,
}) async {
  return await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 600, // 🔥 ancho tipo sistema
        child: AddClienteDialog(cliente: cliente),
      ),
    ),
  );
}

class AddClienteDialog extends ConsumerStatefulWidget {
  final Cliente? cliente;

  const AddClienteDialog({super.key, this.cliente});

  @override
  ConsumerState<AddClienteDialog> createState() => _AddClienteDialogState();
}

class _AddClienteDialogState extends ConsumerState<AddClienteDialog> {
  final _formKey = GlobalKey<FormState>();

  final nombreCtrl = TextEditingController();
  final rncCtrl = TextEditingController(text: '');
  final emailCtrl = TextEditingController(text: '');
  final telefonoCtrl = TextEditingController();
  final direccionCtrl = TextEditingController(text: '');

  bool get isEdit => widget.cliente != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final c = widget.cliente!;
      nombreCtrl.text = c.nombre ?? '';
      emailCtrl.text = c.email ?? '';
      telefonoCtrl.text = c.telefono ?? '';
      direccionCtrl.text = c.direccion ?? '';
      rncCtrl.text = c.documento ?? '';
    }
  }

  void guardar(String token) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = ref.read(clienteAdminProvider.notifier);

    final data = {
      "id": widget.cliente?.id,
      "nombre": nombreCtrl.text.trim(),
      "documento": rncCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "telefono": telefonoCtrl.text.trim(),
      "direccion": direccionCtrl.text.trim(),
      "token": token,
    };

    bool success;
    if (isEdit) {
      success = await provider.updateClient(widget.cliente!.id.toString(), data, token);
    } else {
      success = await provider.createClient(data, token);
    }

    if (success) {
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      final error = ref.read(clienteAdminProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final loading = ref.watch(clienteAdminProvider).isLoading;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 🔝 HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEdit ? 'Editar Cliente' : 'Nuevo Cliente',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// 📋 FORM
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    textFieldWidgetUI(
                      controller: nombreCtrl,
                      label: 'Nombre *',
                    ),
                    textFieldWidgetUI(
                      label: 'Teléfono *',
                      controller: telefonoCtrl,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        PhoneInputFormatter(),
                      ],
                    ),

                    textFieldWidgetUI(
                      controller: direccionCtrl,
                      label: 'Dirección',
                      requiredField: false,
                    ),
                    textFieldWidgetUI(
                      controller: emailCtrl,
                      label: 'Email (Opcional)',
                      requiredField: false,
                    ),
                    textFieldWidgetUI(
                      controller: rncCtrl,
                      label: 'Documento (Opcional)',
                      requiredField: false,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// 🔻 BOTONES
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: loading ? null : () => guardar(auth.token!),
                child: loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Actualizar' : 'Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔧 HELPERS UI
  Widget _buildText(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType? type,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (required && (v == null || v.isEmpty)) return 'Requerido';
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => onChanged(v as String),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
