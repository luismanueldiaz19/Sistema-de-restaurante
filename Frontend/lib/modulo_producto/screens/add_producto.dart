import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        ref.read(impuestosProvider.notifier).fetchAll(token);
      }
    });

    if (isEdit) {
      final p = widget.producto!;
      nombreCtrl.text = p.nombre ?? '';
      codigoCtrl.text = p.codigo ?? '';
      descCtrl.text = p.descripcion ?? '';
      precioCtrl.text = p.precioVenta?.toString() ?? '0';
      costoCtrl.text = p.costo?.toString() ?? '0';
      stockMinimoCtrl.text = p.stockMinimo?.toString() ?? '0';

      cuentaIngresosCtrl.text = p.cuentaIngresoId?.toString() ?? '';
      cuentaInventarioCtrl.text = p.cuentaInventarioId?.toString() ?? '';
      cuentaCostosCtrl.text = p.cuentaCostoId?.toString() ?? '';

      categoriaId = p.categoriaId;
      marcaId = p.marcaId;
      impuestoId = p.impuestoId;

      tipoProducto = p.tipoProducto ?? 'PRODUCTO';
      tipoContable = p.tipoContable ?? 'INVENTARIO';
      manejaInventario = p.manejaInventario ?? true;
      activo = p.activo ?? true;
    }
  }

  void _generarSKU() {
    String name = nombreCtrl.text.trim();
    String prefix = 'PROD';
    if (name.isNotEmpty) {
      final words = name.split(' ').where((w) => w.isNotEmpty).toList();
      if (words.length == 1) {
        prefix = words[0]
            .substring(0, words[0].length < 3 ? words[0].length : 3)
            .toUpperCase();
      } else if (words.length >= 2) {
        prefix = '${words[0][0]}${words[1][0]}'.toUpperCase();
        if (words.length >= 3) {
          prefix += words[2][0].toUpperCase();
        }
      }
    }

    // Clean prefix to keep only letters and numbers
    prefix = prefix.replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (prefix.isEmpty) prefix = 'PROD';

    final randomNum = (1000 + DateTime.now().millisecondsSinceEpoch % 9000)
        .toString();
    setState(() {
      codigoCtrl.text = '$prefix-$randomNum';
    });
  }

  String get _margenGanancia {
    final precio = double.tryParse(precioCtrl.text) ?? 0;
    final costo = double.tryParse(costoCtrl.text) ?? 0;

    if (precio <= 0) return '';
    if (costo == 0 && precio > 0) return ' (100% Margen)';
    if (precio > 0) {
      final margen = ((precio - costo) / precio) * 100;
      return ' (${margen.toStringAsFixed(1)}% Margen)';
    }
    return '';
  }

  void _mostrarCalculadoraCosto() {
    final calcCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Calculadora de Costo',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa el costo total (CON ITBIS) que le pagas al proveedor por unidad:',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: calcCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Costo total con ITBIS',
                prefixText: 'RD\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final val = double.tryParse(calcCtrl.text) ?? 0;
              if (val > 0) {
                final base = val / 1.18; // Extraer ITBIS 18%
                setState(() {
                  costoCtrl.text = base.toStringAsFixed(2);
                });
              }
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.calculate, size: 18),
            label: const Text('Extraer ITBIS (18%)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isAdmin = auth.roles.contains('admin');

    final categorias = ref.watch(categoriasProvider).items;
    final marcas = ref.watch(marcasProvider).items;
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
                        suffixIcon: Icons.autorenew,
                        onSuffixIconTap: _generarSKU,
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
                            child: Text('COMBO / PLATO'),
                          ),
                          DropdownMenuItem(
                            value: 'MATERIA_PRIMA',
                            child: Text('MATERIA PRIMA'),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            tipoProducto = val as String;
                            if (tipoProducto == 'MATERIA_PRIMA') {
                              precioCtrl.text = '0';
                            }
                            if (tipoProducto == 'SERVICIO') {
                              manejaInventario = false;
                            }
                          });
                        },
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
                        enabled: tipoProducto != 'MATERIA_PRIMA',
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomTextField(
                        controller: costoCtrl,
                        label: 'Costo Sin ITBIS',
                        prefixIcon: Icons.shopping_cart_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        enabled: isAdmin,
                        suffixWidget: IconButton(
                          tooltip: 'Extraer ITBIS del Costo',
                          icon: const Icon(
                            Icons.calculate,
                            color: Colors.orange,
                          ),
                          onPressed: _mostrarCalculadoraCosto,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Impuesto General',
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
                const SizedBox(height: 16),

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
      "impuesto_id": impuestoId,
      "tipo_producto": tipoProducto,
      "tipo_contable": tipoContable,
      "precio_venta": double.tryParse(precioCtrl.text) ?? 0,
      "costo": double.tryParse(costoCtrl.text) ?? 0,
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
