import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modulo_cliente/widgets/paginador.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../widgets/custom_loading.dart';
import '../../widgets/custom_text_field.dart';
import '../models/producto.dart';
import '../providers/catalogo_provider.dart';
import '../providers/producto_provider.dart';
import '../widgets/dialog_instrucciones_importacion.dart';
import '../widgets/producto_detail_panel.dart';
import '../widgets/producto_list_card.dart';
import 'add_producto.dart';
import 'screen_preview_import_productos.dart';

class ScreenProductos extends ConsumerStatefulWidget {
  const ScreenProductos({super.key});

  @override
  ConsumerState<ScreenProductos> createState() => _ScreenProductosState();
}

class _ScreenProductosState extends ConsumerState<ScreenProductos> {
  final scrollController = ScrollController();
  final searchController = TextEditingController();
  Producto? selectedProducto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      ref
          .read(productoProvider.notifier)
          .loadProductos(auth.token!, search: '');
      ref.read(categoriasProvider.notifier).fetchAll(auth.token!);
      ref.read(marcasProvider.notifier).fetchAll(auth.token!);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productoProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Inventario de Productos",
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Recargar Productos',
            onPressed: () {
              ref
                  .read(productoProvider.notifier)
                  .loadProductos(auth.token!, search: searchController.text);
            },
          ),
          if (auth.hasPermission('crear_productos'))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: _descargarPlantilla,
                icon: Icon(
                  Icons.download_rounded,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                label: Text(
                  "Plantilla",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: Colors.green.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          if (auth.hasPermission('crear_productos'))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: _showImportInstructions,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text(
                  "Importar",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.azulOscuro,
                  side: const BorderSide(color: AppColors.azulOscuro),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          if (auth.hasPermission('crear_productos'))
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  "Nuevo Producto",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.azulOscuro,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// LADO IZQUIERDO: LISTA DE PRODUCTOS
                Container(
                  width: 340,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.black12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Búsqueda
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CustomTextField(
                          label: "",
                          hintText: "Buscar por nombre o código...",
                          controller: searchController,
                          prefixIcon: Icons.search_rounded,
                          onChanged: (value) => ref
                              .read(productoProvider.notifier)
                              .searchProductos(value, auth.token!),
                          onSuffixIconTap: () {
                            searchController.clear();
                            ref
                                .read(productoProvider.notifier)
                                .searchProductos('', auth.token!);
                            setState(() {});
                          },
                          suffixIcon: searchController.text.isNotEmpty
                              ? Icons.clear_rounded
                              : null,
                        ),
                      ),

                      Expanded(
                        child: Stack(
                          children: [
                            if (!state.isLoading && state.productos.isEmpty)
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 44,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "No hay productos",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                itemCount: state.productos.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final p = state.productos[index];
                                  final isSelected =
                                      selectedProducto?.id == p.id;

                                  return ProductoListCard(
                                    producto: p,
                                    isSelected: isSelected,
                                    canEdit: auth.hasPermission(
                                      "editar_productos",
                                    ),
                                    canDelete: auth.hasPermission(
                                      "eliminar_productos",
                                    ),
                                    onTap: () {
                                      setState(() {
                                        selectedProducto = p;
                                      });
                                    },
                                    onMenuSelected:
                                        (value, productoSelected) async {
                                          if (value == 'edit') {
                                            _showAddEditDialog(
                                              producto: productoSelected,
                                            );
                                          } else if (value == 'delete') {
                                            _deleteProducto(productoSelected);
                                          }
                                        },
                                  );
                                },
                              ),
                            if (state.isLoading)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  child: const CustomLoading(
                                    text: "Cargando productos...",
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      /// Paginador
                      if (state.productos.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Column(
                            children: [
                              Paginador(
                                currentPage: state.currentPage,
                                totalPages: state.totalPages,
                                onPageChanged: (page) {
                                  ref
                                      .read(productoProvider.notifier)
                                      .loadProductos(
                                        auth.token!,
                                        page: page,
                                        search: searchController.text,
                                      );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total de registros: ${state.totalRecords}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                /// LADO DERECHO: DETALLES DEL PRODUCTO
                Expanded(
                  child: selectedProducto == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Selecciona un producto de la lista\npara ver sus detalles",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ProductoDetailPanel(producto: selectedProducto!),
                ),
              ],
            ),
          ),
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
      ref
          .read(productoProvider.notifier)
          .loadProductos(auth.token!, search: '');
      setState(() {
        selectedProducto = null;
      });
    }
  }

  void _deleteProducto(dynamic p) async {
    final auth = ref.read(authProvider);
    if (!auth.hasPermission('eliminar_productos')) return;

    bool? confirm = await CustomConfirmDialog.show(
      context,
      title: 'Eliminar Producto',
      message:
          '¿Estás seguro de eliminar ${p.nombre}? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      primaryColor: Colors.redAccent,
    );

    if (confirm == true) {
      final success = await ref
          .read(productoProvider.notifier)
          .deleteProducto(p.id!, auth.token!);

      if (mounted) {
        if (success) {
          if (selectedProducto?.id == p.id) {
            setState(() {
              selectedProducto = null;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final error = ref.read(productoProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: ${error ?? 'Desconocido'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showImportInstructions() {
    showDialog(
      context: context,
      builder: (context) {
        return DialogInstruccionesImportacion(
          onImport: _importarMasivoConPreview,
          onDownloadTemplate: _descargarPlantilla,
        );
      },
    );
  }

  Future<void> _descargarPlantilla() async {
    try {
      final auth = ref.read(authProvider);
      final bytes = await ref
          .read(productoProvider.notifier)
          .downloadTemplateBytes(auth.token!);

      String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Guardar Plantilla Base de Productos Inventariables',
        fileName: 'plantilla_productos_inventariables.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );

      if (!kIsWeb && outputPath != null) {
        if (!outputPath.toLowerCase().endsWith('.xlsx')) {
          outputPath = '$outputPath.xlsx';
        }
        final file = io.File(outputPath);
        await file.writeAsBytes(bytes, flush: true);
      }

      if (mounted && (kIsWeb || outputPath != null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              outputPath != null
                  ? 'Plantilla descargada en: $outputPath'
                  : 'Plantilla descargada exitosamente.',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error descargando plantilla: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importarMasivoConPreview() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        List<int>? fileBytes = file.bytes;
        if (fileBytes == null && !kIsWeb && file.path != null) {
          fileBytes = await io.File(file.path!).readAsBytes();
        }

        if (fileBytes != null) {
          final auth = ref.read(authProvider);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Analizando y validando archivo...'),
                duration: Duration(seconds: 1),
              ),
            );
          }

          final previewData = await ref
              .read(productoProvider.notifier)
              .previewImportProductos(fileBytes, file.name, auth.token!);

          if (!mounted) return;

          final imported = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ScreenPreviewImportProductos(
                filename: file.name,
                previewData: previewData,
              ),
            ),
          );

          if (imported == true && mounted) {
            setState(() {
              selectedProducto = null;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilterBar() {
    final categorias = ref.watch(categoriasProvider).items;
    final marcas = ref.watch(marcasProvider).items;
    final prodState = ref.watch(productoProvider);
    final auth = ref.read(authProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Text(
            "Categorías:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip(
                    label: "Todas",
                    isSelected: prodState.categoriaId == null,
                    onTap: () => ref
                        .read(productoProvider.notifier)
                        .setCategoriaFilter(null, auth.token!),
                  ),
                  ...categorias.map((c) {
                    return _buildChip(
                      label: c.nombre,
                      isSelected: prodState.categoriaId == c.id,
                      onTap: () => ref
                          .read(productoProvider.notifier)
                          .setCategoriaFilter(c.id, auth.token!),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildCompactDropdown(
            label: "Marca",
            value: prodState.marcaId,
            items: [
              const DropdownMenuItem(value: null, child: Text("Todas")),
              ...marcas.map(
                (m) => DropdownMenuItem(value: m.id, child: Text(m.nombre)),
              ),
            ],
            onChanged: (val) => ref
                .read(productoProvider.notifier)
                .setMarcaFilter(val as int?, auth.token!),
          ),
          const SizedBox(width: 12),
          _buildCompactDropdown(
            label: "Tipo",
            value: prodState.tipoProducto,
            items: const [
              DropdownMenuItem(value: null, child: Text("Todos")),
              DropdownMenuItem(value: "PRODUCTO", child: Text("Productos")),
              DropdownMenuItem(
                value: "MATERIA_PRIMA",
                child: Text("Materia Prima"),
              ),
              DropdownMenuItem(value: "PLATO", child: Text("Platos")),
              DropdownMenuItem(value: "SERVICIO", child: Text("Servicios")),
              DropdownMenuItem(value: "COMBO", child: Text("Combos")),
            ],
            onChanged: (val) => ref
                .read(productoProvider.notifier)
                .setTipoProductoFilter(val as String?, auth.token!),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.azulOscuro : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.azulOscuro : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required Function(dynamic) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label:",
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: items.any((e) => e.value == value) ? value : null,
              isDense: true,
              style: const TextStyle(fontSize: 11.5, color: Colors.black87),
              icon: const Icon(Icons.arrow_drop_down, size: 16),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
