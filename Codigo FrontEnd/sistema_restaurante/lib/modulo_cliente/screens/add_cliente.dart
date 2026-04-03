import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class AddClienteDialog extends StatefulWidget {
  final Cliente? cliente;

  const AddClienteDialog({super.key, this.cliente});

  @override
  State<AddClienteDialog> createState() => _AddClienteDialogState();
}

class _AddClienteDialogState extends State<AddClienteDialog> {
  final _formKey = GlobalKey<FormState>();

  final nombreCtrl = TextEditingController();
  final rncCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final limiteCtrl = TextEditingController(text: '50000');
  final diasCtrl = TextEditingController(text: '30');

  final codigoCuentaCxcCtrl = TextEditingController();

  String tipoEntidad = 'FISICA';
  String tipoIdentificacion = 'CEDULA';
  String tipoPrecio = 'one';
  String condicionPago = 'contado';
  String estado = 'activo';

  bool loading = false;

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
    }
  }

  void guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final provider = Provider.of<ClienteAdminProvider>(context, listen: false);

    final data = {
      "id": widget.cliente?.id,
      "nombre": nombreCtrl.text.trim(),
      "rnc_cedula": rncCtrl.text.trim(),
      "tipo_entidad": tipoEntidad,
      "tipo_identificacion": tipoIdentificacion,
      "email": emailCtrl.text.trim(),
      "telefono": telefonoCtrl.text.trim(),
      "direccion": direccionCtrl.text.trim(),
      "limite_credito": double.tryParse(limiteCtrl.text) ?? 0,
      "dias_credito": int.tryParse(diasCtrl.text) ?? 0,
      "tipo_precio": tipoPrecio,
      "condicion_pago_default": condicionPago,
      "estado": estado,
      "codigo_cuenta_cxc": codigoCuentaCxcCtrl.text.trim(),
      // "usuario_id": currentUsuario?.idUsuario,
    };

    print(data);

    try {
      if (isEdit) {
        // await provider.updateCliente(data);
      } else {
        // await provider.addCliente(data);
      }

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
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

          const Divider(),

          /// 📋 FORM
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildText(nombreCtrl, 'Nombre *', required: true),
                    _buildText(telefonoCtrl, 'Teléfono'),
                    _buildText(direccionCtrl, 'Dirección'),
                    _buildText(emailCtrl, 'Email (Opcional)'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Tipo Entidad',
                            tipoEntidad,
                            ['FISICA', 'JURIDICA'],
                            (v) => setState(() => tipoEntidad = v),
                          ),
                        ),
                        Expanded(
                          child: _buildDropdown(
                            'Tipo Identificación',
                            tipoIdentificacion,
                            ['CEDULA', 'RNC', 'PASAPORTE'],
                            (v) => setState(() => tipoIdentificacion = v),
                          ),
                        ),
                        Expanded(child: _buildText(rncCtrl, 'RNC/Cédula')),
                      ],
                    ),

                    // if (currentUsuario!.tienePermiso('admin', 'admin'))
                    //   Row(
                    //     children: [
                    //       Expanded(
                    //         child: _buildText(limiteCtrl, 'Límite Crédito',
                    //             type: TextInputType.number),
                    //       ),
                    //       Expanded(
                    //         child: _buildText(diasCtrl, 'Días Crédito',
                    //             type: TextInputType.number),
                    //       ),
                    //       Expanded(
                    //         child: _buildText(
                    //             codigoCuentaCxcCtrl, 'Cuenta contable'),
                    //       ),
                    //     ],
                    //   ),
                    // if (currentUsuario!.tienePermiso('admin', 'admin'))
                    //   Row(
                    //     children: [
                    //       Expanded(
                    //         child: _buildDropdown(
                    //           'Tipo Precio',
                    //           tipoPrecio,
                    //           ['one', 'two', 'three'],
                    //           (v) => setState(() => tipoPrecio = v),
                    //         ),
                    //       ),
                    //       Expanded(
                    //         child: _buildDropdown(
                    //           'Condición de Pago',
                    //           condicionPago,
                    //           ['contado', 'credito', 'contra_entrega'],
                    //           (v) => setState(() => condicionPago = v),
                    //         ),
                    //       ),
                    //       Expanded(
                    //         child: _buildDropdown(
                    //           'Estado',
                    //           estado,
                    //           ['activo', 'inactivo'],
                    //           (v) => setState(() => estado = v),
                    //         ),
                    //       )
                    //     ],
                    //   ),
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
                onPressed: loading ? null : guardar,
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
