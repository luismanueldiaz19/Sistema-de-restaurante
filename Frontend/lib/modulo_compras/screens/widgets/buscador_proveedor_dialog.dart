import 'package:flutter/material.dart';
import '../../models/proveedor.dart';
import 'add_proveedor_dialog.dart';

class BuscadorProveedorDialog extends StatefulWidget {
  final List<Proveedor> proveedores;

  const BuscadorProveedorDialog({super.key, required this.proveedores});

  @override
  State<BuscadorProveedorDialog> createState() => _BuscadorProveedorDialogState();
}

class _BuscadorProveedorDialogState extends State<BuscadorProveedorDialog> {
  List<Proveedor> filtrados = [];
  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtrados = widget.proveedores;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Seleccionar Proveedor"),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (_) => const AddProveedorDialog(),
              );
              if (result == true && context.mounted) {
                // Return null to caller so they can re-open or just rely on state updating.
                // Ideally, we fetch and auto-select.
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nuevo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            // 🔍 BUSCADOR
            TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                hintText: "Buscar proveedor...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  filtrados = widget.proveedores
                      .where(
                        (p) => (p.nombre).toLowerCase().contains(
                          value.toLowerCase(),
                        ) || (p.rnc ?? "").toLowerCase().contains(
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
                  final proveedor = filtrados[index];

                  return Card(
                    child: ListTile(
                      title: Text(proveedor.nombre),
                      subtitle: Text(
                        "RNC: ${proveedor.rnc ?? 'N/A'} | Tel: ${proveedor.telefono ?? 'N/A'}",
                      ),
                      onTap: () {
                        Navigator.pop(
                          context,
                          proveedor,
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
