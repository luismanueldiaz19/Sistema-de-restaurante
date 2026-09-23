import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../modulo_cliente/models/cliente.dart';
import '../../../modulo_cliente/services/cliente_api.dart';
import '../../../modulo_cliente/widgets/client_list_card.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/custom_empty_state.dart';
import '../../../widgets/custom_loading.dart';
import '../../../widgets/custom_text_field.dart';

/// 🔍 DIALOGO BUSCADOR
class BuscadorClienteDialog extends ConsumerStatefulWidget {
  final List<Cliente> clientes;

  const BuscadorClienteDialog({super.key, required this.clientes});

  @override
  ConsumerState<BuscadorClienteDialog> createState() =>
      _BuscadorClienteDialogState();
}

class _BuscadorClienteDialogState extends ConsumerState<BuscadorClienteDialog> {
  List<Cliente> filtrados = [];
  TextEditingController searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    filtrados = widget.clientes;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }

  void _searchClients(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        filtrados = widget.clientes;
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);

      final token = ref.read(authProvider).token;
      if (token == null) return;

      try {
        final api = ClienteApi();
        final response = await api.fetchClients(token, search: query);
        setState(() {
          filtrados = response['clientes'] as List<Cliente>;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Seleccionar cliente",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            // 🔍 BUSCADOR
            CustomTextField(
              controller: searchCtrl,
              label: '',
              hintText: 'Buscar por nombre, cédula o email...',
              prefixIcon: Icons.search,
              onChanged: _searchClients,
            ),

            const SizedBox(height: 10),

            // 📋 LISTA
            Expanded(
              child: _isLoading
                  ? const CustomLoading(
                      size: 60,
                      colorText: Colors.black87,
                      text: "Buscando clientes...",
                    )
                  : filtrados.isEmpty
                  ? const CustomEmptyState(title: "No se encontraron clientes")
                  : ListView.separated(
                      itemCount: filtrados.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cliente = filtrados[index];

                        return ClientListCard(
                          cliente: cliente,
                          isSelected: false,
                          onTap: () {
                            Navigator.pop(
                              context,
                              cliente,
                            ); // 🔥 devuelve el objeto
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
