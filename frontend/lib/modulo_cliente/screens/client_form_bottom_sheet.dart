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
    final isDesktop = MediaQuery.of(context).size.width > 600;
    if (isDesktop) {
      return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => ClientFormBottomSheet(cliente: cliente),
      );
    }
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
        ref
            .read(configuracionContableProvider.notifier)
            .loadAllData(auth.token!);
      }
    });

    final c = widget.cliente;
    nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    rncCtrl = TextEditingController(text: c?.rncCedula ?? '');
    emailCtrl = TextEditingController(text: c?.email ?? '');
    telefonoCtrl = TextEditingController(text: c?.telefono ?? '');
    direccionCtrl = TextEditingController(text: c?.direccion ?? '');
    limiteCreditoCtrl = TextEditingController(
      text: (c?.limiteCredito ?? 0) > 0 ? c!.limiteCredito.toString() : '0',
    );
    diasCreditoCtrl = TextEditingController(
      text: (c?.diasCredito ?? 0) > 0 ? c!.diasCredito.toString() : '0',
    );
    cuentaContableCtrl = TextEditingController(
      text: c?.cuentaContable ?? '1.1.03.01',
    );
    descuentoFijoCtrl = TextEditingController(
      text: (c?.descuentoFijo ?? 0) > 0 ? c!.descuentoFijo.toString() : '0',
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
    final isAdmin = auth.isAdmin || auth.roles.contains('admin');
    final provider = ref.read(clienteAdminProvider.notifier);

    final data = {
      "nombre": nombreCtrl.text.trim(),
      "rnc_cedula": rncCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "telefono": telefonoCtrl.text.trim(),
      "direccion": direccionCtrl.text.trim(),
      "tipo_cliente": isAdmin
          ? tipoCliente
          : (widget.cliente?.tipoCliente ?? 'consumidor_final'),
      "limite_credito": isAdmin
          ? (double.tryParse(limiteCreditoCtrl.text) ?? 0)
          : (widget.cliente?.limiteCredito ?? 0),
      "dias_credito": isAdmin
          ? (int.tryParse(diasCreditoCtrl.text) ?? 0)
          : (widget.cliente?.diasCredito ?? 0),
      "cuenta_contable": isAdmin
          ? cuentaContableCtrl.text.trim()
          : (widget.cliente?.cuentaContable ?? '1.1.03.01'),
      "descuento_fijo": isAdmin
          ? (double.tryParse(descuentoFijoCtrl.text) ?? 0)
          : (widget.cliente?.descuentoFijo ?? 0),
      "activo": isAdmin ? activo : (widget.cliente?.activo ?? true),
      "notas": isAdmin ? notasCtrl.text.trim() : (widget.cliente?.notas ?? ''),
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
        const SnackBar(
          content: Text('No hay cuentas transaccionales disponibles.'),
        ),
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
    final auth = ref.watch(authProvider);
    final isAdmin = auth.isAdmin || auth.roles.contains('admin');
    final isLoading = ref.watch(clienteAdminProvider).isLoading;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    final content = Container(
      width: isDesktop ? 580 : size.width,
      constraints: BoxConstraints(
        maxHeight: size.height * 0.88,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop
            ? BorderRadius.circular(14)
            : const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDesktop) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],

          // Cabecera Enterprise
          _buildHeader(context),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Contenido del Formulario
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.person_outline,
                      title: 'Datos Básicos del Cliente',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: CustomTextField(
                            controller: nombreCtrl,
                            label: 'Nombre Completo / Razón Social',
                            hintText: 'Ej. Juan Pérez o Empresa S.R.L.',
                            prefixIcon: Icons.person_outline,
                            validator: (v) => v!.trim().isEmpty
                                ? 'El nombre es obligatorio'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            controller: telefonoCtrl,
                            label: 'Teléfono',
                            hintText: '(809) 000-0000',
                            prefixIcon: Icons.phone_outlined,
                            validator: (v) => v!.trim().isEmpty
                                ? 'El teléfono es obligatorio'
                                : null,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              PhoneInputFormatter(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: rncCtrl,
                            label: 'RNC / Cédula',
                            hintText: 'Ej. 001-0000000-0',
                            prefixIcon: Icons.badge_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            controller: emailCtrl,
                            label: 'Correo Electrónico',
                            hintText: 'correo@ejemplo.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: direccionCtrl,
                      label: 'Dirección',
                      hintText: 'Calle, número, sector o ciudad...',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 1,
                    ),

                    // SECCIONES AVANZADAS: EXCLUSIVO PARA ADMINISTRADORES
                    if (isAdmin) ...[
                      const SizedBox(height: 18),
                      _buildSectionHeader(
                        icon: Icons.credit_card_outlined,
                        title: 'Condiciones Comerciales y Crédito',
                        badgeText: 'ADMIN',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dropdown Tipo Cliente
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tipo de Cliente',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                DropdownButtonFormField<String>(
                                  initialValue: tipoCliente,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() {
                                        tipoCliente = v;
                                        if (tipoCliente == 'credito' &&
                                            (int.tryParse(
                                                        diasCreditoCtrl.text) ??
                                                    0) ==
                                                0) {
                                          diasCreditoCtrl.text = '30';
                                        }
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.category_outlined,
                                      size: 15,
                                      color: AppColors.azulOscuro
                                          .withValues(alpha: 0.7),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      borderSide: BorderSide(
                                        color: AppColors.azulOscuro,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: CustomTextField(
                              controller: diasCreditoCtrl,
                              label: 'Días Crédito',
                              hintText: 'Ej. 30',
                              prefixIcon: Icons.calendar_today_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              controller: limiteCreditoCtrl,
                              label: 'Límite Crédito (RD\$)',
                              hintText: '0.00',
                              prefixIcon: Icons.attach_money_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: descuentoFijoCtrl,
                              label: '% Descuento Fijo',
                              hintText: 'Ej. 5',
                              prefixIcon: Icons.percent_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(top: 17),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'Cliente Activo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const Spacer(),
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Switch(
                                      value: activo,
                                      onChanged: (val) =>
                                          setState(() => activo = val),
                                      activeThumbColor: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildSectionHeader(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Contabilidad y Observaciones',
                        badgeText: 'ADMIN',
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _seleccionarCuentaContable,
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: cuentaContableCtrl,
                            label: 'Cuenta Contable (CxC Clientes)',
                            prefixIcon: Icons.account_tree_outlined,
                            hintText: 'Seleccionar cuenta...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: notasCtrl,
                        label: 'Notas / Observaciones',
                        hintText:
                            'Condiciones especiales, referencias o comentarios...',
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 2,
                        keyboardType: TextInputType.multiline,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Footer Enterprise
          _buildFooter(context, isLoading),
        ],
      ),
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: content,
      );
    }

    return content;
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.azulOscuro.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
              size: 17,
              color: AppColors.azulOscuro,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Editar Cliente' : 'Nuevo Cliente',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isEdit
                      ? 'Actualice los datos generales y de facturación'
                      : 'Complete la información para registrar el nuevo cliente',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: 16,
            color: Colors.grey.shade500,
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? badgeText,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.azulOscuro),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppColors.azulOscuro.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.azulOscuro.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.azulOscuro,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _guardar,
            icon: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 16),
            label: Text(
              isEdit ? 'Actualizar Cliente' : 'Guardar Cliente',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulOscuro,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        width: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Buscar Cuenta Contable',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.azulOscuro,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                )
              ],
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _searchCtrl,
              label: '',
              hintText: 'Buscar por código o nombre...',
              prefixIcon: Icons.search,
              onChanged: _filtrar,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filtradas.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron cuentas.',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filtradas.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: Color(0xFFF1F5F9),
                      ),
                      itemBuilder: (context, index) {
                        final c = _filtradas[index];
                        return ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          leading: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.azulOscuro.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.account_tree_outlined,
                              color: AppColors.azulOscuro,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            c.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Text(
                            c.codigo,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
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
