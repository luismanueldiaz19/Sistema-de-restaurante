import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import '../../utils/phone_input_formatter.dart';
import '../../widgets/custom_text_field.dart';
import '../models/cliente.dart';
import '../providers/cliente_admin_provider.dart';
import '../../providers/configuracion_contable_provider.dart';
import '../../model/catalogo_cuenta_model.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.token != null) {
        ref.read(configuracionContableProvider.notifier).loadAllData(auth.token!);
      }
    });

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

  void _seleccionarCuentaContable() async {
    final state = ref.read(configuracionContableProvider);
    final cuentas = state.catalogoCuentasCompleto
        .where((c) => c.permiteMovimiento)
        .toList();

    if (cuentas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cuentas transaccionales disponibles.')),
      );
      return;
    }

    final cuentaSeleccionada = await showDialog<CatalogoCuentaModel>(
      context: context,
      builder: (ctx) => _AccountSelectorDialog(cuentas: cuentas),
    );

    if (cuentaSeleccionada != null) {
      setState(() {
        cuentaContableCtrl.text = cuentaSeleccionada.codigo;
      });
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
                    _buildSectionCard(
                      title: "Información Básica",
                      icon: Icons.person_outline,
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
                      ],
                    ),

                    if (isAdmin) ...[
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: "Configuración Contable y Avanzada",
                        icon: Icons.account_balance_wallet_outlined,
                        children: [
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
                            onChanged: (v) => setState(() => tipoCliente = v!),
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Cliente',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _seleccionarCuentaContable,
                            child: AbsorbPointer(
                              child: CustomTextField(
                                controller: cuentaContableCtrl,
                                label: 'Cuenta Contable',
                                prefixIcon: Icons.account_tree_outlined,
                                hintText: 'Buscar en catálogo...',
                              ),
                            ),
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
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  controller: diasCreditoCtrl,
                                  label: 'Días Crédito',
                                  prefixIcon: Icons.calendar_today_outlined,
                                  keyboardType: TextInputType.number,
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
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Estado del Cliente',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const Spacer(),
                                Switch(
                                  value: activo,
                                  onChanged: (val) => setState(() => activo = val),
                                  activeColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: notasCtrl,
                            label: 'Notas / Observaciones',
                            prefixIcon: Icons.note_outlined,
                            maxLines: 3,
                            keyboardType: TextInputType.multiline,
                          ),
                        ],
                      ),
                    ],

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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.azulOscuro.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.azulOscuro, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _AccountSelectorDialog extends StatefulWidget {
  final List<CatalogoCuentaModel> cuentas;

  const _AccountSelectorDialog({required this.cuentas});

  @override
  State<_AccountSelectorDialog> createState() => _AccountSelectorDialogState();
}

class _AccountSelectorDialogState extends State<_AccountSelectorDialog> {
  final _searchCtrl = TextEditingController();
  late List<CatalogoCuentaModel> _filtradas;

  @override
  void initState() {
    super.initState();
    _filtradas = widget.cuentas;
  }

  void _filtrar(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filtradas = widget.cuentas);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtradas = widget.cuentas.where((c) {
        return c.codigo.toLowerCase().contains(q) ||
               c.nombre.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Buscar Cuenta Contable',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                )
              ],
            ),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _searchCtrl,
              label: '',
              hintText: 'Buscar por código o nombre...',
              prefixIcon: Icons.search,
              onChanged: _filtrar,
            ),
            const SizedBox(height: 15),
            Expanded(
              child: _filtradas.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron cuentas.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filtradas.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = _filtradas[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.azulOscuro.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.account_tree_outlined, color: AppColors.azulOscuro, size: 20),
                          ),
                          title: Text(
                            c.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(c.codigo),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
