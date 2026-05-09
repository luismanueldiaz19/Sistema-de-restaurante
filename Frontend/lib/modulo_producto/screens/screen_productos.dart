import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../widgets/custom_loading.dart';
import '../../widgets/custom_text_field.dart';
import '../providers/producto_provider.dart';
import '../widgets/producto_table.dart';
import 'add_producto.dart';

class ScreenProductos extends ConsumerStatefulWidget {
  const ScreenProductos({super.key});

  @override
  ConsumerState<ScreenProductos> createState() => _ScreenProductosState();
}

class _ScreenProductosState extends ConsumerState<ScreenProductos> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      ref.read(productoProvider.notifier).loadProductos(auth.token!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productoProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Inventario de Productos",
          style: TextStyle(color: AppColors.azulOscuro, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          if (auth.hasPermission('crear_productos'))
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Nuevo Producto"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulOscuro,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            child: CustomTextField(
              label: "",
              hintText: "Buscar por nombre, código o categoría...",
              controller: searchController,
              prefixIcon: Icons.search_rounded,
              onChanged: (v) => ref.read(productoProvider.notifier).searchProductos(v),
              onSuffixIconTap: () {
                searchController.clear();
                ref.read(productoProvider.notifier).searchProductos('');
              },
              suffixIcon: searchController.text.isNotEmpty ? Icons.clear_rounded : null,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: state.isLoading && state.productos.isEmpty
                  ? const CustomLoading(text: "Cargando productos...")
                  : state.productos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 80,
                                color: Colors.grey.shade200,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "No hay productos registrados",
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ProductoTable(
                          productos: state.productos,
                          onEdit: (p) => _showAddEditDialog(producto: p),
                          onDelete: (p) => _deleteProducto(p),
                        ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAddEditDialog({dynamic producto}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddProductoDialog(producto: producto),
    );
    if (result == true) {
      final auth = ref.read(authProvider);
      ref.read(productoProvider.notifier).loadProductos(auth.token!);
    }
  }

  void _deleteProducto(dynamic p) async {
    final auth = ref.read(authProvider);
    if (!auth.roles.contains('admin')) return;

    bool? confirm = await CustomConfirmDialog.show(
      context,
      title: 'Eliminar Producto',
      message: '¿Estás seguro de eliminar ${p.nombre}? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      primaryColor: Colors.redAccent,
    );

    if (confirm == true) {
      await ref.read(productoProvider.notifier).deleteProducto(p.id!, auth.token!);
    }
  }
}
