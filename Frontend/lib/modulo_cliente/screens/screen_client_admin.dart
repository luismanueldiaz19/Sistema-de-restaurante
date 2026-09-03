import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../widgets/custom_loading.dart';
import '../../widgets/custom_text_field.dart';
import '../providers/cliente_admin_provider.dart';
import '../widgets/paginador.dart';
import 'client_form_bottom_sheet.dart';
import '../models/cliente.dart';
import '../widgets/client_detail_panel.dart';
import '../widgets/client_list_card.dart';

class ScreenClientAdmin extends ConsumerStatefulWidget {
  const ScreenClientAdmin({super.key});

  @override
  ConsumerState<ScreenClientAdmin> createState() => _ScreenClientAdminState();
}

class _ScreenClientAdminState extends ConsumerState<ScreenClientAdmin> {
  final scrollController = ScrollController();
  final searchController = TextEditingController();
  Cliente? selectedClient;

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Clientes",
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar Clientes',
            onPressed: () {
              ref.read(clienteAdminProvider.notifier).loadClients(auth.token!);
            },
          ),
          if (auth.permissions.contains("crear_clientes"))
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await ClientFormBottomSheet.show(context);
                  if (result == true) {
                    ref.read(clienteAdminProvider.notifier).loadClients(auth.token!);
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LADO IZQUIERDO: LISTA DE CLIENTES
          Container(
            width: 450,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.black12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Búsqueda
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: CustomTextField(
                    label: "",
                    hintText: "Buscar por nombre o WhatsApp...",
                    controller: searchController,
                    prefixIcon: Icons.search_rounded,
                    onChanged: (value) => ref
                        .read(clienteAdminProvider.notifier)
                        .searchClientes(value, auth.token!),
                    onSuffixIconTap: () {
                      searchController.clear();
                      ref
                          .read(clienteAdminProvider.notifier)
                          .searchClientes('', auth.token!);
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
                      if (!provider.isLoading && provider.clientes.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off_outlined,
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
                            horizontal: 15,
                            vertical: 10,
                          ),
                          itemCount: provider.clientes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final cliente = provider.clientes[index];
                            final isSelected = selectedClient?.id == cliente.id;

                            return ClientListCard(
                              cliente: cliente,
                              isSelected: isSelected,
                              canEdit: auth.hasPermission("editar_clientes"),
                              canDelete: auth.hasPermission("eliminar_clientes"),
                              onTap: () {
                                setState(() {
                                  selectedClient = cliente;
                                });
                              },
                              onMenuSelected: (value, clienteSelected) async {
                                if (value == 'edit') {
                                  final result = await ClientFormBottomSheet.show(
                                    context,
                                    cliente: clienteSelected,
                                  );
                                  if (result == true) {
                                    ref.read(clienteAdminProvider.notifier).loadClients(auth.token!);
                                    setState(() {
                                      selectedClient = null;
                                    });
                                  }
                                } else if (value == 'delete') {
                                  bool? ask = await CustomConfirmDialog.show(
                                    context,
                                    title: 'Eliminar Cliente',
                                    message: '¿Estás seguro que deseas eliminar a ${clienteSelected.nombre}?',
                                    confirmText: 'Eliminar',
                                    cancelText: 'Cancelar',
                                    icon: Icons.delete_forever_rounded,
                                    primaryColor: Colors.redAccent,
                                  );
                                  if (ask == true) {
                                    ref.read(clienteAdminProvider.notifier).deleteClient(clienteSelected.id!, auth.token!);
                                    if (selectedClient?.id == clienteSelected.id) {
                                      setState(() {
                                        selectedClient = null;
                                      });
                                    }
                                  }
                                }
                              },
                            );
                          },
                        ),
                      if (provider.isLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.5),
                            child: const CustomLoading(
                              text: "Cargando clientes...",
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                /// Paginador
                if (provider.clientes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                    child: Paginador(
                      currentPage: provider.currentPage,
                      totalPages: provider.totalPages,
                      onPageChanged: (page) {
                        ref.read(clienteAdminProvider.notifier).loadClients(
                          auth.token!,
                          page: page,
                          search: searchController.text,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          /// LADO DERECHO: DETALLES DEL CLIENTE
          Expanded(
            child: selectedClient == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 100,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Selecciona un cliente de la lista\npara ver sus detalles",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                : ClientDetailPanel(cliente: selectedClient!),
          ),
        ],
      ),
    );
  }
}
