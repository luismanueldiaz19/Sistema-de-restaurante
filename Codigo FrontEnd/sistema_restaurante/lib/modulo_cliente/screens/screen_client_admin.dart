import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          // if (currentUsuario!.tienePermiso('cliente', 'crear'))
          //   IconButton(
          //     onPressed: () async {
          //       await showAddClienteDialog(context);
          //     },
          //     icon: Icon(Icons.person_add_alt_1_outlined),
          //   ),
        ],
      ),
      body: Column(
        children: [
          /// 🔎 BUSCADOR
          const SizedBox(width: double.infinity),
          textFieldWidgetUI(
            label: 'Buscar cliente - ${provider.clientes.length}',
            suffixIcon: Icons.search,
            onChanged: (value) {
              // provider.buscar(value);
            },
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
            )
          else
            Text('No hay cliente'),

          if (provider.isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(),
              ),
            ),

          /// 📄 PAGINACIÓN
          // if (provider.clientes.isNotEmpty)
          //   Paginador(
          //     currentPage: provider.currentPage,
          //     totalPages: provider.totalPages,
          //     onPageChanged: (page) {
          //       provider.goToPage(page);
          //     },
          //   ),
        ],
      ),
    );
  }
}
