import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sistema_restaurante/utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../providers/cliente_admin_provider.dart';
import '../widgets/cliente_admin_table.dart';
import '../widgets/paginador.dart';
import 'add_cliente.dart';

class ScreenClientAdmin extends StatefulWidget {
  const ScreenClientAdmin({super.key});

  @override
  State createState() => _ScreenClientAdminState();
}

class _ScreenClientAdminState extends State<ScreenClientAdmin> {
  late ClienteAdminProvider provider;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = Provider.of<ClienteAdminProvider>(context, listen: false);
      final auth = context.read<AuthProvider>();
      provider.loadClients(auth.token!);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClienteAdminProvider>(context);
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de clientes"),
        actions: [
          if (auth.permissions.contains("crear_clientes"))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: IconButton(
                onPressed: () async {
                  await showAddClienteDialog(context);
                },
                icon: Icon(Icons.person_add_alt_1_outlined),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔎 BUSCADOR
          // const SizedBox(width: double.infinity),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: textFieldWidgetUI(
              label: 'Buscar cliente - ${provider.clientes.length}',
              suffixIcon: Icons.search,
              onChanged: (value) {
                provider.searchClientes(value);
              },
            ),
          ),
          const SizedBox(height: 10),

          /// 📊 TABLA
          if (provider.clientes.isNotEmpty)
            ClienteAdminTable(
              clientes: provider.clientes,
              onEdit: (cliente) async {
                final result = await showAddClienteDialog(
                  context,
                  cliente: cliente,
                );

                if (result == true) {
                  Provider.of<ClienteAdminProvider>(
                    context,
                    listen: false,
                  ).loadClients(auth.token!);
                }
              },
              onDelete: (cliente) async {
                bool? ask = await showConfirmationDialogOnyAsk(
                  context,
                  eliminarMjs,
                );

                if (ask != null && ask) {
                  print('puede eliminar');
                  Provider.of<ClienteAdminProvider>(
                    context,
                    listen: false,
                  ).deleteClient(cliente.id!, auth.token!);
                }
              },
            )
          else
            Expanded(child: Text('No hay cliente')),

          if (provider.isLoading)
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          // / 📄 PAGINACIÓN
          if (provider.clientes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 25),
              child: Paginador(
                currentPage: 1,
                totalPages: provider.clientes.length,
                onPageChanged: (page) {
                  // provider.goToPage(page);
                },
              ),
            ),
        ],
      ),
    );
  }
}
