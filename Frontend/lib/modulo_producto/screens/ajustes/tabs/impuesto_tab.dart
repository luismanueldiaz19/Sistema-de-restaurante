import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/catalogo_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/catalogo_form_dialog.dart';

class ImpuestoTab extends ConsumerStatefulWidget {
  const ImpuestoTab({super.key});

  @override
  ConsumerState<ImpuestoTab> createState() => _ImpuestoTabState();
}

class _ImpuestoTabState extends ConsumerState<ImpuestoTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(impuestosProvider.notifier).fetchAll(token);
      }
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => CatalogoFormDialog(
        title: 'Nueva Impuesto',
        fields: [
          CatalogoFieldConfig(key: 'nombre', label: 'Nombre'),
          CatalogoFieldConfig(key: 'tasa', label: 'Tasa (%)', isNumber: true),
        ],
        onSubmit: (data) async {
          final token = ref.read(authProvider).token!;
          await ref.read(impuestosProvider.notifier).create(token, data);
        },
      ),
    );
  }

  void _showEditDialog(dynamic item) {
    showDialog(
      context: context,
      builder: (_) => CatalogoFormDialog(
        title: 'Editar Impuesto',
        fields: [
          CatalogoFieldConfig(
            key: 'nombre',
            label: 'Nombre',
            initialValue: item.nombre,
          ),
          CatalogoFieldConfig(
            key: 'tasa',
            label: 'Tasa (%)',
            isNumber: true,
            initialValue: item.tasa.toString(),
          ),
        ],
        onSubmit: (data) async {
          final token = ref.read(authProvider).token!;
          await ref
              .read(impuestosProvider.notifier)
              .updateItem(token, item.id, data);
        },
      ),
    );
  }

  void _delete(int id) async {
    final token = ref.read(authProvider).token!;
    await ref.read(impuestosProvider.notifier).deleteItem(token, id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(impuestosProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar Impuesto'),
                onPressed: _showAddDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Tasa (%)')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: state.items
                    .map(
                      (item) => DataRow(
                        cells: [
                          DataCell(Text(item.id.toString())),
                          DataCell(Text(item.nombre)),
                          DataCell(Text(item.tasa.toStringAsFixed(2))),
                          DataCell(
                            Icon(
                              item.activo ? Icons.check_circle : Icons.cancel,
                              color: item.activo ? Colors.green : Colors.red,
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showEditDialog(item),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _delete(item.id),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
