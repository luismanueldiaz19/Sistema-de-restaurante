import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../utils/phone_input_formatter.dart';
import '../../widgets/custom_text_field.dart';
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
  final limiteCreditoCtrl = TextEditingController(text: '0');
  final diasCreditoCtrl = TextEditingController(text: '0');
  final cuentaContableCtrl = TextEditingController(text: '1.1.03.01');
  final descuentoFijoCtrl = TextEditingController(text: '0');
  final notasCtrl = TextEditingController(text: '');

  String tipoCliente = 'consumidor_final';
  bool activo = true;

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
      rncCtrl.text = c.rncCedula ?? '';
      limiteCreditoCtrl.text = (c.limiteCredito ?? 0).toString();
      diasCreditoCtrl.text = (c.diasCredito ?? 0).toString();
      cuentaContableCtrl.text = c.cuentaContable ?? '';
      descuentoFijoCtrl.text = (c.descuentoFijo ?? 0).toString();
      notasCtrl.text = c.notas ?? '';
      tipoCliente = c.tipoCliente ?? 'consumidor_final';
      activo = c.activo ?? true;
    }
  }

  void guardar(String token) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = ref.read(clienteAdminProvider.notifier);

    final data = {
      "id": widget.cliente?.id,
      "nombre": nombreCtrl.text.trim(),
      "rnc_cedula": rncCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "telefono": telefonoCtrl.text.trim(),
      "direccion": direccionCtrl.text.trim(),
      "tipo_cliente": tipoCliente,
      "limite_credito": double.tryParse(limiteCreditoCtrl.text) ?? 0,
      "dias_credito": int.tryParse(diasCreditoCtrl.text) ?? 0,
      "cuenta_contable": cuentaContableCtrl.text.trim(),
      "descuento_fijo": double.tryParse(descuentoFijoCtrl.text) ?? 0,
      "activo": activo,
      "notas": notasCtrl.text.trim(),
      "token": token,
    };

    bool success;
    if (isEdit) {
      success = await provider.updateClient(
        widget.cliente!.id.toString(),
        data,
        token,
      );
    } else {
      success = await provider.createClient(data, token);
    }

    if (success) {
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      final error = ref.read(clienteAdminProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección Datos Básicos
                    const Text(
                      'DATOS BÁSICOS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: textFieldWidgetUI(
                            controller: nombreCtrl,
                            label: 'Nombre o Razón Social *',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: textFieldWidgetUI(
                            controller: rncCtrl,
                            label: 'RNC / Cédula',
                            requiredField: false,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: textFieldWidgetUI(
                            label: 'Teléfono *',
                            controller: telefonoCtrl,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              PhoneInputFormatter(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: textFieldWidgetUI(
                            controller: emailCtrl,
                            label: 'Email',
                            requiredField: false,
                          ),
                        ),
                      ],
                    ),
                    textFieldWidgetUI(
                      controller: direccionCtrl,
                      label: 'Dirección Completa',
                      requiredField: false,
                      width: double.infinity,
                    ),

                    const SizedBox(height: 20),
                    // Sección Configuración Financiera
                    const Text(
                      'CONFIGURACIÓN FINANCIERA Y CONTABLE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Tipo de Cliente',
                            tipoCliente,
                            [
                              {
                                'val': 'consumidor_final',
                                'label': 'Consumidor Final',
                              },
                              {'val': 'credito', 'label': 'Crédito / Fiao'},
                              {
                                'val': 'gubernamental',
                                'label': 'Gubernamental',
                              },
                              {'val': 'especial', 'label': 'Especial'},
                            ],
                            auth.roles.contains('admin')
                                ? (val) => setState(() => tipoCliente = val)
                                : null, // Deshabilitar si no es admin
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            controller: cuentaContableCtrl,
                            label: 'Cuenta Contable',
                            hintText: '1.1.03.01',
                            enabled: false,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: textFieldWidgetUI(
                            controller: limiteCreditoCtrl,
                            label: 'Límite de Crédito',
                            keyboardType: TextInputType.number,
                            requiredField: false,
                            enabled: auth.roles.contains('admin'),
                            readOnly: !auth.roles.contains('admin'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: textFieldWidgetUI(
                            controller: diasCreditoCtrl,
                            label: 'Días de Crédito',
                            keyboardType: TextInputType.number,
                            requiredField: false,
                            enabled: auth.roles.contains('admin'),
                            readOnly: !auth.roles.contains('admin'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: textFieldWidgetUI(
                            controller: descuentoFijoCtrl,
                            label: '% Descuento Fijo',
                            keyboardType: TextInputType.number,
                            requiredField: false,
                            enabled: auth.roles.contains('admin'),
                            readOnly: !auth.roles.contains('admin'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    // Estado y Notas
                    Row(
                      children: [
                        const Text('¿Cliente Activo?'),
                        Switch(
                          value: activo,
                          onChanged: auth.roles.contains('admin')
                              ? (val) => setState(() => activo = val)
                              : null,
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                    textFieldWidgetUI(
                      controller: notasCtrl,
                      label: 'Notas Internas / Observaciones',
                      requiredField: false,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'ACTUALIZAR CLIENTE' : 'CREAR CLIENTE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔧 HELPERS UI
  Widget _buildDropdown(
    String label,
    String value,
    List<Map<String, String>> items,
    Function(String)? onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map(
              (e) =>
                  DropdownMenuItem(value: e['val'], child: Text(e['label']!)),
            )
            .toList(),
        onChanged: onChanged != null ? (v) => onChanged(v!) : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
  }
}
