import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../widgets/custom_loading.dart';
import '../../widgets/custom_text_field.dart';
import '../providers/proveedores_provider.dart';
import '../models/proveedor.dart';
import 'widgets/add_proveedor_dialog.dart';
import 'widgets/proveedor_detail_panel.dart';
import 'widgets/proveedor_list_card.dart';

class ProveedoresScreen extends ConsumerStatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  ConsumerState<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends ConsumerState<ProveedoresScreen> {
  final scrollController = ScrollController();
  final searchController = TextEditingController();
  Proveedor? selectedProveedor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proveedoresProvider.notifier).loadProveedores();
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<Proveedor> _getFilteredProveedores(List<Proveedor> allProveedores) {
    if (searchController.text.isEmpty) {
      return allProveedores;
    }
    final query = searchController.text.toLowerCase();
    return allProveedores.where((p) {
      return p.nombre.toLowerCase().contains(query) ||
          (p.rnc != null && p.rnc!.toLowerCase().contains(query)) ||
          (p.telefono != null && p.telefono!.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proveedoresProvider);
    final proveedores = _getFilteredProveedores(state.proveedores);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Proveedores",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar Proveedores',
            onPressed: () {
              ref.read(proveedoresProvider.notifier).loadProveedores();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (_) => const AddProveedorDialog(),
                );
                if (result == true) {
                  ref.read(proveedoresProvider.notifier).loadProveedores();
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Nuevo Proveedor"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LADO IZQUIERDO: LISTA DE PROVEEDORES
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
                    hintText: "Buscar por nombre, RNC o teléfono...",
                    controller: searchController,
                    prefixIcon: Icons.search_rounded,
                    onChanged: (value) => setState(() {}),
                    onSuffixIconTap: () {
                      searchController.clear();
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
                      if (!state.isLoading && proveedores.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store_mall_directory_outlined,
                                size: 50,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Sin resultados",
                                style: TextStyle(color: Colors.grey.shade500),
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
                          itemCount: proveedores.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final proveedor = proveedores[index];
                            final isSelected =
                                selectedProveedor?.id == proveedor.id;

                            return ProveedorListCard(
                              proveedor: proveedor,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  selectedProveedor = proveedor;
                                });
                              },
                              onMenuSelected: (value, provSelected) async {
                                if (value == 'edit') {
                                  final result = await showDialog(
                                    context: context,
                                    builder: (_) => AddProveedorDialog(
                                      proveedor: provSelected,
                                    ),
                                  );
                                  if (result == true) {
                                    ref
                                        .read(proveedoresProvider.notifier)
                                        .loadProveedores();
                                    setState(() {
                                      selectedProveedor = null;
                                    });
                                  }
                                } else if (value == 'delete') {
                                  bool? ask = await CustomConfirmDialog.show(
                                    context,
                                    title: 'Eliminar Proveedor',
                                    message:
                                        '¿Estás seguro que deseas eliminar a ${provSelected.nombre}?',
                                    confirmText: 'Eliminar',
                                    cancelText: 'Cancelar',
                                    icon: Icons.delete_forever_rounded,
                                    primaryColor: Colors.redAccent,
                                  );
                                  if (ask == true) {
                                    final success = await ref
                                        .read(proveedoresProvider.notifier)
                                        .deleteProveedor(provSelected.id);
                                    if (success) {
                                      if (selectedProveedor?.id ==
                                          provSelected.id) {
                                        setState(() {
                                          selectedProveedor = null;
                                        });
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Proveedor eliminado correctamente',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
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
                              text: "Cargando proveedores...",
                            ),
                          ),
                        ),
                      if (state.error != null && !state.isLoading)
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              'Error: ${state.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// LADO DERECHO: DETALLES DEL PROVEEDOR
          Expanded(
            child: selectedProveedor == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 100,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Selecciona un proveedor de la lista\npara ver sus detalles",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                : ProveedorDetailPanel(proveedor: selectedProveedor!),
          ),
        ],
      ),
    );
  }
}
