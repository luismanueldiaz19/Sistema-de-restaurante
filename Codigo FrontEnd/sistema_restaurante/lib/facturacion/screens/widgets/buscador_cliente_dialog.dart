import 'package:flutter/material.dart';

import '../../../modulo_cliente/models/cliente.dart';

/// 🔍 DIALOGO BUSCADOR
class BuscadorClienteDialog extends StatefulWidget {
  final List<Cliente> clientes;

  const BuscadorClienteDialog({super.key, required this.clientes});

  @override
  State<BuscadorClienteDialog> createState() => _BuscadorClienteDialogState();
}

class _BuscadorClienteDialogState extends State<BuscadorClienteDialog> {
  List<Cliente> filtrados = [];
  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtrados = widget.clientes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Seleccionar cliente"),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            // 🔍 BUSCADOR
            TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                hintText: "Buscar cliente...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  filtrados = widget.clientes
                      .where(
                        (c) => (c.nombre ?? "").toLowerCase().contains(
                          value.toLowerCase(),
                        ),
                      )
                      .toList();
                });
              },
            ),

            const SizedBox(height: 10),

            // 📋 LISTA
            Expanded(
              child: ListView.builder(
                itemCount: filtrados.length,
                itemBuilder: (context, index) {
                  final cliente = filtrados[index];

                  return Card(
                    child: ListTile(
                      title: Text(cliente.nombre ?? ''),
                      subtitle: Text(
                        "${cliente.telefono ?? ''} ${cliente.email ?? ''}",
                      ),
                      onTap: () {
                        Navigator.pop(
                          context,
                          cliente,
                        ); // 🔥 devuelve el objeto
                      },
                    ),
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
