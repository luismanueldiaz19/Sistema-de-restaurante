import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../models/producto.dart';
import '../providers/producto_provider.dart';
import '../providers/catalogo_provider.dart';

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
  final stockMinimoCtrl = TextEditingController(text: '0');

  final cuentaIngresosCtrl = TextEditingController(text: '');
  final cuentaInventarioCtrl = TextEditingController(text: '');
  final cuentaCostosCtrl = TextEditingController(text: '');

  int? categoriaId;
  int? marcaId;
  int? unidadMedidaId;
  int? impuestoId;

  String tipoProducto = 'PRODUCTO';
  String tipoContable = 'INVENTARIO';
  bool manejaInventario = true;
  bool activo = true;

  bool get isEdit => widget.producto != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(categoriasProvider.notifier).fetchAll(token);
        ref.read(marcasProvider.notifier).fetchAll(token);
        ref.read(unidadesProvider.notifier).fetchAll(token);
        ref.read(impuestosProvider.notifier).fetchAll(token);
      }
    });

    if (isEdit) {
      final p = widget.producto!;
      nombreCtrl.text = p.nombre ?? '';
      codigoCtrl.text = p.codigo ?? '';
      descCtrl.text = p.descripcion ?? '';
      precioCtrl.text = p.precioVenta?.toString() ?? '0';
      costoCtrl.text = p.ultimoCosto?.toString() ?? '0';
      stockMinimoCtrl.text = p.stockMinimo?.toString() ?? '0';

      cuentaIngresosCtrl.text = p.cuentaIngresoId?.toString() ?? '';
      cuentaInventarioCtrl.text = p.cuentaInventarioId?.toString() ?? '';
      cuentaCostosCtrl.text = p.cuentaCostoId?.toString() ?? '';

      categoriaId = p.categoriaId;
      marcaId = p.marcaId;
      unidadMedidaId = p.unidadMedidaId;
      impuestoId = p.impuestoId;

      tipoProducto = p.tipoProducto ?? 'PRODUCTO';
      tipoContable = p.tipoContable ?? 'INVENTARIO';
      manejaInventario = p.manejaInventario ?? true;
      activo = p.activo ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isAdmin = auth.roles.contains('admin');

    final categorias = ref.watch(categoriasProvider).items;
    final marcas = ref.watch(marcasProvider).items;
    final unidades = ref.watch(unidadesProvider).items;
    final impuestos = ref.watch(impuestosProvider).items;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
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
                        label: 'Codigo / SKU',
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
                        items: const [
                          DropdownMenuItem(
                            value: 'PRODUCTO',
                            child: Text('PRODUCTO'),
                          ),
                          DropdownMenuItem(
                            value: 'SERVICIO',
                            child: Text('SERVICIO'),
                          ),
                          DropdownMenuItem(
                            value: 'COMBO',
                            child: Text('COMBO'),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => tipoProducto = val as String),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Tipo Contable',
                        value: tipoContable,
                        items: const [
                          DropdownMenuItem(
                            value: 'INVENTARIO',
                            child: Text('INVENTARIO'),
                          ),
                          DropdownMenuItem(
                            value: 'GASTO',
                            child: Text('GASTO'),
                          ),
                          DropdownMenuItem(
                            value: 'SERVICIO',
                            child: Text('SERVICIO'),
                          ),
                          DropdownMenuItem(
                            value: 'ACTIVO_FIJO',
                            child: Text('ACTIVO_FIJO'),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => tipoContable = val as String),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Categoria',
                        value: categoriaId,
                        items: categorias
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(e.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => categoriaId = val as int?),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Marca',
                        value: marcaId,
                        items: marcas
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(e.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => marcaId = val as int?),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Unidad de Medida',
                        value: unidadMedidaId,
                        items: unidades
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text("${e.nombre} (${e.abreviatura})"),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => unidadMedidaId = val as int?),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  'CONFIGURACION FINANCIERA',
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
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomTextField(
                        controller: costoCtrl,
                        label: 'Ultimo Costo (Compra)',
                        prefixIcon: Icons.shopping_cart_outlined,
                        keyboardType: TextInputType.number,
                        enabled: isAdmin,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Impuesto Aplicado',
                        value: impuestoId,
                        items: impuestos
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text("${e.nombre} (${e.tasa}%)"),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => impuestoId = val as int?),
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
                        controller: stockMinimoCtrl,
                        label: 'Stock Minimo (Alerta)',
                        enabled: manejaInventario,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Row(
                        children: [
                          const Text(
                            'Activo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Switch(
                            value: activo,
                            onChanged: (v) => setState(() => activo = v),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
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
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required Function(dynamic) onChanged,
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
            child: DropdownButton<dynamic>(
              value: items.any((e) => e.value == value) ? value : null,
              isExpanded: true,
              hint: const Text("Seleccionar..."),
              items: items,
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
      "categoria_id": categoriaId,
      "marca_id": marcaId,
      "unidad_medida_id": unidadMedidaId,
      "impuesto_id": impuestoId,
      "tipo_producto": tipoProducto,
      "tipo_contable": tipoContable,
      "precio_venta": double.tryParse(precioCtrl.text) ?? 0,
      "ultimo_costo": double.tryParse(costoCtrl.text) ?? 0,
      "maneja_inventario": manejaInventario,
      "stock_minimo": double.tryParse(stockMinimoCtrl.text) ?? 0,
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
