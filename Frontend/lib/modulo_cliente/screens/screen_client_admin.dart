import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/palletes/app_colors.dart';
import 'package:sistema_restaurante/utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../widgets/custom_loading.dart';
import '../../widgets/custom_text_field.dart';
import '../providers/cliente_admin_provider.dart';
import '../widgets/cliente_admin_table.dart';
import '../widgets/paginador.dart';
import 'client_form_bottom_sheet.dart';

class ScreenClientAdmin extends ConsumerStatefulWidget {
  const ScreenClientAdmin({super.key});

  @override
  ConsumerState<ScreenClientAdmin> createState() => _ScreenClientAdminState();
}

class _ScreenClientAdminState extends ConsumerState<ScreenClientAdmin> {
  final scrollController = ScrollController();
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      ref.read(clienteAdminProvider.notifier).loadClients(auth.token!);
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
    final provider = ref.watch(clienteAdminProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Administración de Clientes",
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          if (auth.permissions.contains("crear_clientes"))
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await ClientFormBottomSheet.show(context);
                  if (result == true) {
                    ref
                        .read(clienteAdminProvider.notifier)
                        .loadClients(auth.token!);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Nuevo Cliente"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulOscuro,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔎 BARRA DE BÚSQUEDA MODERNA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: "",
                    hintText: "Buscar por nombre, teléfono o RNC...",
                    controller: searchController,
                    prefixIcon: Icons.search_rounded,
                    onChanged: (value) => ref
                        .read(clienteAdminProvider.notifier)
                        .searchClientes(value),
                    onSuffixIconTap: () {
                      searchController.clear();
                      ref
                          .read(clienteAdminProvider.notifier)
                          .searchClientes('');
                      setState(() {});
                    },
                    suffixIcon: searchController.text.isNotEmpty
                        ? Icons.clear_rounded
                        : null,
                  ),
                ),
                const SizedBox(width: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: AppColors.azulOscuro.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${provider.clientes.length} Clientes",
                    style: const TextStyle(
                      color: AppColors.azulOscuro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 📊 CONTENIDO (TABLA O LOADING)
          Expanded(
            child: Stack(
              children: [
                if (provider.clientes.isEmpty && !provider.isLoading)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "No se encontraron clientes",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Positioned.fill(
                    child: ClienteAdminTable(
                      clientes: provider.clientes,
                      onEdit: (cliente) async {
                        if (!auth.hasPermission("editar_clientes")) return;
                        final result = await ClientFormBottomSheet.show(
                          context,
                          cliente: cliente,
                        );
                        if (result == true) {
                          ref
                              .read(clienteAdminProvider.notifier)
                              .loadClients(auth.token!);
                        }
                      },
                      onDelete: (cliente) async {
                        if (!auth.hasPermission("eliminar_clientes")) return;
                        bool? ask = await CustomConfirmDialog.show(
                          context,
                          title: 'Eliminar Cliente',
                          message:
                              '¿Estás seguro que deseas eliminar a ${cliente.nombre}? Esta acción no se puede deshacer.',
                          confirmText: 'Eliminar',
                          cancelText: 'Cancelar',
                          icon: Icons.delete_forever_rounded,
                          primaryColor: Colors.redAccent,
                        );
                        if (ask == true) {
                          ref
                              .read(clienteAdminProvider.notifier)
                              .deleteClient(cliente.id!, auth.token!);
                        }
                      },
                    ),
                  ),

                if (provider.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.8),
                      child: const CustomLoading(text: "Cargando clientes..."),
                    ),
                  ),
              ],
            ),
          ),

          /// 📄 PAGINACIÓN
          if (provider.clientes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Paginador(
                currentPage: 1,
                totalPages: 1,
                onPageChanged: (page) {},
              ),
            ),
        ],
      ),
    );
  }
}
