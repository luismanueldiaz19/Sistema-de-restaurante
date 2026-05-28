import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../providers/compras_provider.dart';
import '../providers/proveedores_provider.dart';
import '../../modulo_producto/providers/producto_provider.dart';
import '../../modulo_producto/providers/producto_state.dart';
import '../../modulo_producto/models/producto.dart';
import '../../utils/helpers.dart';
import 'widgets/buscador_proveedor_dialog.dart';

class NuevaCompraScreen extends ConsumerStatefulWidget {
  const NuevaCompraScreen({super.key});

  @override
  ConsumerState<NuevaCompraScreen> createState() => _NuevaCompraScreenState();
}

class _NuevaCompraScreenState extends ConsumerState<NuevaCompraScreen> {
  final numFacturaCtrl = TextEditingController();
  final ncfCtrl = TextEditingController();
  final notasCtrl = TextEditingController();

  DateTime fechaCompra = DateTime.now();
  DateTime? fechaVencimiento;
  String tipoCompra = 'CONTADO';
  int? selectedProveedorId;
  String _searchQuery = "";

  List<Map<String, dynamic>> detalles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proveedoresProvider.notifier).loadProveedores();
      final token = ref.read(comprasProvider.notifier).token;
      if (token != null) {
        ref.read(productoProvider.notifier).loadProductos(token, silent: true);
      }
    });
  }

  double get _subtotal => detalles.fold(
        0,
        (sum, item) => sum + (item['cantidad'] * item['costo_unitario']),
      );
  double get _impuestos =>
      detalles.fold(0, (sum, item) => sum + item['impuesto_monto']);
  double get _total => _subtotal + _impuestos;

  void _limpiarFormulario() {
    setState(() {
      numFacturaCtrl.clear();
      ncfCtrl.clear();
      notasCtrl.clear();
      fechaCompra = DateTime.now();
      fechaVencimiento = null;
      tipoCompra = 'CONTADO';
      selectedProveedorId = null;
      detalles.clear();
    });
  }

  void _guardarCompra() async {
    if (selectedProveedorId == null) {
      showToast(context, 'Seleccione un proveedor', bgColor: Colors.orange);
      return;
    }
    if (numFacturaCtrl.text.isEmpty) {
      showToast(context, 'Ingrese número de factura', bgColor: Colors.orange);
      return;
    }
    if (detalles.isEmpty) {
      showToast(context, 'Agregue al menos un producto al carrito', bgColor: Colors.orange);
      return;
    }
    if (tipoCompra == 'CREDITO' && fechaVencimiento == null) {
      showToast(context, 'Seleccione fecha de vencimiento', bgColor: Colors.orange);
      return;
    }

    final data = {
      'proveedor_id': selectedProveedorId,
      'numero_factura_proveedor': numFacturaCtrl.text,
      'ncf': ncfCtrl.text,
      'fecha_compra': fechaCompra.toIso8601String().split('T')[0],
      'fecha_vencimiento': fechaVencimiento?.toIso8601String().split('T')[0],
      'tipo_compra': tipoCompra,
      'notas': notasCtrl.text,
      'detalles': detalles
          .map(
            (d) => {
              'producto_id': d['producto_id'],
              'cantidad': d['cantidad'],
              'costo_unitario': d['costo_unitario'],
              'impuesto_monto': d['impuesto_monto'],
            },
          )
          .toList(),
    };

    final success = await ref.read(comprasProvider.notifier).createCompra(data);
    if (success && mounted) {
      showToast(context, 'Compra registrada con éxito', bgColor: Colors.green);
      _limpiarFormulario();
    } else if (mounted) {
      showToast(context, 'Error al registrar compra', bgColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provState = ref.watch(proveedoresProvider);
    final prodState = ref.watch(productoProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registro de Compras',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
              ),
            ),
            Text(
              'Gestión de inventario y cuentas por pagar',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          const SizedBox(width: 12),
          _buildCircleButton(
            icon: Icons.delete_sweep_outlined,
            color: Colors.redAccent,
            onTap: _limpiarFormulario,
            tooltip: 'Limpiar Todo',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth < 1100;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📋 PANEL IZQUIERDO: CONFIGURACIÓN
              if (!isTablet)
                SizedBox(
                  width: 320,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildConfiguracionCompra(provState),
                  ),
                ),

              // 🍕 PANEL CENTRAL: CATÁLOGO
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _buildProductCatalog(prodState),
                      ),
                    ),
                  ],
                ),
              ),

              // 🛒 PANEL DERECHO: CARRITO Y TOTALES
              SizedBox(
                width: isTablet ? 340 : 400,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 24, 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _buildCarritoCompra(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPanelTotales(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildConfiguracionCompra(provState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos del Documento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 20),
        if (provState.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          InkWell(
            onTap: () async {
              final prov = await showDialog(
                context: context,
                builder: (ctx) => BuscadorProveedorDialog(proveedores: provState.proveedores),
              );
              if (prov != null) {
                setState(() => selectedProveedorId = prov.id);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedProveedorId != null
                          ? (() {
                              final matched = provState.proveedores.where((p) => p.id == selectedProveedorId).toList();
                              return matched.isNotEmpty ? matched.first.nombre : 'Proveedor Seleccionado';
                            })()
                          : 'Seleccionar Proveedor',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: numFacturaCtrl,
          label: 'Nº Factura',
          prefixIcon: Icons.receipt_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: ncfCtrl,
          label: 'NCF',
          prefixIcon: Icons.article_outlined,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Tipo',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          value: tipoCompra,
          items: const [
            DropdownMenuItem(value: 'CONTADO', child: Text('CONTADO')),
            DropdownMenuItem(value: 'CREDITO', child: Text('CRÉDITO')),
          ],
          onChanged: (val) => setState(() => tipoCompra = val!),
        ),
        const SizedBox(height: 16),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: Colors.white,
          title: const Text('Fecha de Compra', style: TextStyle(fontSize: 14)),
          subtitle: Text(
            fechaCompra.toLocal().toString().split(' ')[0],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: fechaCompra,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => fechaCompra = date);
          },
        ),
        const SizedBox(height: 16),
        if (tipoCompra == 'CREDITO') ...[
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: Colors.white,
            title: const Text('Vencimiento', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              fechaVencimiento?.toLocal().toString().split(' ')[0] ?? 'Seleccionar',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.event, size: 20, color: Colors.orange),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: fechaVencimiento ?? fechaCompra,
                firstDate: fechaCompra,
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => fechaVencimiento = date);
            },
          ),
          const SizedBox(height: 16),
        ],
        CustomTextField(
          controller: notasCtrl,
          label: 'Notas (Opcional)',
          prefixIcon: Icons.note_alt_outlined,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildProductCatalog(ProductoState prodState) {
    if (prodState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final filteredProducts = prodState.productos.where((p) {
      final name = p.nombre?.toLowerCase() ?? "";
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto por nombre o código...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final prod = filteredProducts[index];
                    return _buildProductCard(prod);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Producto prod) {
    return InkWell(
      onTap: () => _showProductModal(prod),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prod.nombre ?? 'Sin nombre',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Costo Ref: ${formatCurrency(prod.ultimoCosto ?? 0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'No se encontraron productos',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showProductModal(Producto prod) {
    final cantCtrl = TextEditingController(text: '1');
    final costoCtrl = TextEditingController(text: (prod.ultimoCosto ?? 0).toString());
    final impCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Comprar: ${prod.nombre}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: cantCtrl,
                  label: 'Cantidad',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: costoCtrl,
                  label: 'Costo Unitario',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: impCtrl,
                  label: 'Monto Impuesto (Total)',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (cantCtrl.text.isEmpty || costoCtrl.text.isEmpty) return;
                setState(() {
                  detalles.add({
                    'producto_id': prod.id,
                    'producto_nombre': prod.nombre,
                    'cantidad': double.parse(cantCtrl.text),
                    'costo_unitario': double.parse(costoCtrl.text),
                    'impuesto_monto': double.parse(impCtrl.text),
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Agregar al Carrito'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarritoCompra() {
    if (detalles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Carrito Vacío',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agregue productos desde el catálogo',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.shopping_cart_checkout_outlined, color: AppColors.primary),
              SizedBox(width: 10),
              Text(
                'Detalle de Compra',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.black12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: detalles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final d = detalles[i];
              final totalItem = (d['cantidad'] * d['costo_unitario']) + d['impuesto_monto'];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['producto_nombre'] ?? 'Sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cant: ${d['cantidad']} x ${formatCurrency(d['costo_unitario'])}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          if (d['impuesto_monto'] > 0)
                            Text(
                              '+ Impuesto: ${formatCurrency(d['impuesto_monto'])}',
                              style: const TextStyle(color: AppColors.danger, fontSize: 11),
                            )
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency(totalItem),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => setState(() => detalles.removeAt(i)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPanelTotales() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalRow('Subtotal', _subtotal),
          const SizedBox(height: 12),
          _buildTotalRow('Impuestos', _impuestos),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.black12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Final',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                formatCurrency(_total),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: ref.watch(comprasProvider).isLoading ? null : _guardarCompra,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: ref.watch(comprasProvider).isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline, size: 24),
              label: const Text(
                'REGISTRAR COMPRA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          formatCurrency(amount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
