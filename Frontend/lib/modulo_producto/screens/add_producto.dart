import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../models/producto.dart';
import '../providers/producto_provider.dart';

class AddProductoDialog extends ConsumerStatefulWidget {
  final Producto? producto;
  const AddProductoDialog({super.key, this.producto});

  @override
  ConsumerState<AddProductoDialog> createState() => _AddProductoDialogState();
}

class _AddProductoDialogState extends ConsumerState<AddProductoDialog> {
  final _formKey = GlobalKey<FormState>();

  final nombreCtrl = TextEditingController();
  final codigoCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final precioCtrl = TextEditingController(text: '0');
  final costoCtrl = TextEditingController(text: '0');
  final itbisCtrl = TextEditingController(text: '18');
  final stockActualCtrl = TextEditingController(text: '0');
  final stockMinimoCtrl = TextEditingController(text: '0');

  // Cuentas contables por defecto
  final cuentaIngresosCtrl = TextEditingController(text: '4.1.01');
  final cuentaInventarioCtrl = TextEditingController(text: '1.1.05.01');
  final cuentaCostosCtrl = TextEditingController(text: '5.1');

  String categoria = 'COMIDA';
  String tipoProducto = 'VENTA_DIRECTA';
  String unidadMedida = 'UND';
  bool manejaInventario = true;
  bool activo = true;

  bool get isEdit => widget.producto != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final p = widget.producto!;
      nombreCtrl.text = p.nombre ?? '';
      codigoCtrl.text = p.codigo ?? '';
      descCtrl.text = p.descripcion ?? '';
      unidadMedida = p.unidadMedida ?? 'UND';
      precioCtrl.text = p.precioVenta?.toString() ?? '0';
      costoCtrl.text = p.costo?.toString() ?? '0';
      itbisCtrl.text = p.itbisPorcentaje?.toString() ?? '18';
      stockActualCtrl.text = p.stockActual?.toString() ?? '0';
      stockMinimoCtrl.text = p.stockMinimo?.toString() ?? '0';
      cuentaIngresosCtrl.text = p.cuentaContableIngresos ?? '4.1.01';
      cuentaInventarioCtrl.text = p.cuentaContableInventario ?? '1.1.05.01';
      cuentaCostosCtrl.text = p.cuentaContableCostos ?? '5.1';
      categoria = p.categoria ?? 'COMIDA';
      tipoProducto = p.tipoProducto ?? 'VENTA_DIRECTA';
      manejaInventario = p.manejaInventario ?? true;
      activo = p.activo ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isAdmin = auth.roles.contains('admin');

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
                      isEdit ? 'Editar Producto' : 'Nuevo Producto',
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

                // Información básica
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: nombreCtrl,
                        label: 'Nombre del Producto',
                        hintText: 'Ej: Hamburguesa con Queso',
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomTextField(
                        controller: codigoCtrl,
                        label: 'Código / SKU',
                        hintText: 'HAM-001',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Tipo de Producto',
                        value: tipoProducto,
                        items: ['VENTA_DIRECTA', 'PLATO'],
                        onChanged: (val) => setState(() => tipoProducto = val!),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Categoría',
                        value: categoria,
                        items: ['COMIDA', 'BEBIDA', 'SERVICIOS', 'OTROS'],
                        onChanged: (val) => setState(() => categoria = val!),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomTextField(
                        controller: descCtrl,
                        label: 'Descripción Corta',
                        hintText: 'Opcional...',
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Unidad Medida',
                        value: unidadMedida,
                        items: [
                          "UND",
                          "KG",
                          "LB",
                          "GR",
                          "ONZ",
                          "LT",
                          "ML",
                          "GAL",
                          "DOC",
                          "PAR",
                          "BAN",
                          "POR",
                          "ROL",
                          "BOT",
                          "LAT",
                          "TAZ",
                          "VAS",
                          "PAQ",
                          "SER",
                          "PZA",
                          "CJA",
                          "MED",
                        ],
                        onChanged: (val) => setState(() => unidadMedida = val!),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  'CONFIGURACIÓN FINANCIERA',
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
                      child: CustomTextField(
                        controller: precioCtrl,
                        label: 'Precio de Venta',
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomTextField(
                        controller: costoCtrl,
                        label: 'Costo (Compra)',
                        prefixIcon: Icons.shopping_cart_outlined,
                        keyboardType: TextInputType.number,
                        enabled: isAdmin,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomTextField(
                        controller: itbisCtrl,
                        label: '% ITBIS',
                        prefixIcon: Icons.percent,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  'INVENTARIO Y CONTROL',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Maneja Inventario',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: manejaInventario,
                            onChanged: (v) =>
                                setState(() => manejaInventario = v),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CustomTextField(
                        controller: stockActualCtrl,
                        label: 'Stock Actual',
                        enabled: manejaInventario,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomTextField(
                        controller: stockMinimoCtrl,
                        label: 'Stock Mínimo',
                        enabled: manejaInventario,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                if (isAdmin) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'CONFIGURACIÓN CONTABLE (ADMIN)',
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
                        child: CustomTextField(
                          controller: cuentaIngresosCtrl,
                          label: 'Cuenta Ingresos',
                          hintText: '4.1.01',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          controller: cuentaInventarioCtrl,
                          label: 'Cuenta Inventario',
                          hintText: '1.1.05.01',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          controller: cuentaCostosCtrl,
                          label: 'Cuenta Costos',
                          hintText: '5.1',
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Producto Activo'),
                    const Spacer(),
                    Switch(
                      value: activo,
                      onChanged: (v) => setState(() => activo = v),
                      activeColor: Colors.green,
                    ),
                  ],
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'Actualizar Producto' : 'Crear Producto',
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

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final provider = ref.read(productoProvider.notifier);

    final data = {
      "nombre": nombreCtrl.text.trim(),
      "codigo": codigoCtrl.text.trim(),
      "descripcion": descCtrl.text.trim(),
      "categoria": categoria,
      "tipo_producto": tipoProducto,
      "unidad_medida": unidadMedida,
      "precio_venta": double.tryParse(precioCtrl.text) ?? 0,
      "costo": double.tryParse(costoCtrl.text) ?? 0,
      "itbis_porcentaje": double.tryParse(itbisCtrl.text) ?? 18,
      "maneja_inventario": manejaInventario,
      "stock_actual": double.tryParse(stockActualCtrl.text) ?? 0,
      "stock_minimo": double.tryParse(stockMinimoCtrl.text) ?? 0,
      "cuenta_contable_ingresos": cuentaIngresosCtrl.text.trim(),
      "cuenta_contable_inventario": cuentaInventarioCtrl.text.trim(),
      "cuenta_contable_costos": cuentaCostosCtrl.text.trim(),
      "activo": activo,
    };

    bool success;
    if (isEdit) {
      success = await provider.updateProducto(
        widget.producto!.id.toString(),
        data,
        auth.token!,
      );
    } else {
      success = await provider.createProducto(data, auth.token!);
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
