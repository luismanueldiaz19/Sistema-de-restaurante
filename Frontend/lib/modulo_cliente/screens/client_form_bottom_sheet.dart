import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import '../../utils/phone_input_formatter.dart';
import '../../widgets/custom_text_field.dart';
import '../models/cliente.dart';
import '../providers/cliente_admin_provider.dart';

class ClientFormBottomSheet extends ConsumerStatefulWidget {
  final Cliente? cliente;

  const ClientFormBottomSheet({super.key, this.cliente});

  static Future<bool?> show(BuildContext context, {Cliente? cliente}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClientFormBottomSheet(cliente: cliente),
    );
  }

  @override
  ConsumerState<ClientFormBottomSheet> createState() =>
      _ClientFormBottomSheetState();
}

class _ClientFormBottomSheetState extends ConsumerState<ClientFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nombreCtrl;
  late final TextEditingController rncCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController telefonoCtrl;
  late final TextEditingController direccionCtrl;
  late final TextEditingController limiteCreditoCtrl;
  late final TextEditingController diasCreditoCtrl;
  late final TextEditingController cuentaContableCtrl;
  late final TextEditingController descuentoFijoCtrl;
  late final TextEditingController notasCtrl;

  String tipoCliente = 'consumidor_final';
  bool activo = true;

  bool get isEdit => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    rncCtrl = TextEditingController(text: c?.rncCedula ?? '');
    emailCtrl = TextEditingController(text: c?.email ?? '');
    telefonoCtrl = TextEditingController(text: c?.telefono ?? '');
    direccionCtrl = TextEditingController(text: c?.direccion ?? '');
    limiteCreditoCtrl = TextEditingController(
      text: (c?.limiteCredito ?? 0).toString(),
    );
    diasCreditoCtrl = TextEditingController(
      text: (c?.diasCredito ?? 0).toString(),
    );
    cuentaContableCtrl = TextEditingController(
      text: c?.cuentaContable ?? '1.1.03.01',
    );
    descuentoFijoCtrl = TextEditingController(
      text: (c?.descuentoFijo ?? 0).toString(),
    );
    notasCtrl = TextEditingController(text: c?.notas ?? '');
    tipoCliente = c?.tipoCliente ?? 'consumidor_final';
    activo = c?.activo ?? true;
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    rncCtrl.dispose();
    emailCtrl.dispose();
    telefonoCtrl.dispose();
    direccionCtrl.dispose();
    limiteCreditoCtrl.dispose();
    diasCreditoCtrl.dispose();
    cuentaContableCtrl.dispose();
    descuentoFijoCtrl.dispose();
    notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final provider = ref.read(clienteAdminProvider.notifier);

    final data = {
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
    };

    final success = isEdit
        ? await provider.updateClient(
            widget.cliente!.id.toString(),
            data,
            auth.token!,
          )
        : await provider.createClient(data, auth.token!);

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(clienteAdminProvider).isLoading;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final auth = ref.watch(authProvider);
    final isAdmin = auth.roles.contains('admin');

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handlebar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Editar Cliente' : 'Nuevo Cliente',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: nombreCtrl,
                      label: 'Nombre Completo',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          v!.isEmpty ? 'El nombre es obligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: telefonoCtrl,
                            label: 'Teléfono',
                            prefixIcon: Icons.phone_outlined,
                            validator: (v) => v!.isEmpty
                                ? 'El teléfono es obligatorio'
                                : null,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              PhoneInputFormatter(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: rncCtrl,
                            label: 'RNC / Cédula',
                            prefixIcon: Icons.badge_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: emailCtrl,
                      label: 'Correo Electrónico',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: direccionCtrl,
                      label: 'Dirección',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Configuración Contable',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const Divider(),

                    DropdownButtonFormField<String>(
                      value: tipoCliente,
                      items: const [
                        DropdownMenuItem(
                          value: 'consumidor_final',
                          child: Text('Consumidor Final'),
                        ),
                        DropdownMenuItem(
                          value: 'credito',
                          child: Text('Crédito'),
                        ),
                        DropdownMenuItem(
                          value: 'gubernamental',
                          child: Text('Gubernamental'),
                        ),
                        DropdownMenuItem(
                          value: 'especial',
                          child: Text('Especial'),
                        ),
                      ],
                      onChanged: isAdmin
                          ? (v) => setState(() => tipoCliente = v!)
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Cliente',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: cuentaContableCtrl,
                      label: 'Cuenta Contable',
                      prefixIcon: Icons.account_tree_outlined,
                      hintText: 'Ej: 1.1.03.01',
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: limiteCreditoCtrl,
                            label: 'Límite Crédito',
                            prefixIcon: Icons.money_off_outlined,
                            keyboardType: TextInputType.number,
                            enabled: isAdmin,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: diasCreditoCtrl,
                            label: 'Días Crédito',
                            prefixIcon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                            enabled: isAdmin,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: descuentoFijoCtrl,
                      label: '% Descuento Fijo',
                      prefixIcon: Icons.percent_outlined,
                      keyboardType: TextInputType.number,
                      enabled: isAdmin,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Cliente Activo'),
                        const Spacer(),
                        Switch(
                          value: activo,
                          onChanged: isAdmin
                              ? (val) => setState(() => activo = val)
                              : null,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: notasCtrl,
                      label: 'Notas / Observaciones',
                      prefixIcon: Icons.note_outlined,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulOscuro,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isEdit
                                    ? 'Actualizar Cliente'
                                    : 'Guardar Cliente',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
