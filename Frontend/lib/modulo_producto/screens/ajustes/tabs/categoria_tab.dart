import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/catalogo_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/catalogo_form_dialog.dart';

class CategoriaTab extends ConsumerStatefulWidget {
  const CategoriaTab({super.key});

  @override
  ConsumerState<CategoriaTab> createState() => _CategoriaTabState();
}

class _CategoriaTabState extends ConsumerState<CategoriaTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(categoriasProvider.notifier).fetchAll(token);
      }
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => CatalogoFormDialog(
        title: 'Nueva Categoría',
        fields: [
          CatalogoFieldConfig(key: 'nombre', label: 'Nombre'),
          CatalogoFieldConfig(key: 'descripcion', label: 'Descripción'),
        ],
        onSubmit: (data) async {
          final token = ref.read(authProvider).token!;
          await ref.read(categoriasProvider.notifier).create(token, data);
        },
      ),
    );
  }

  void _showEditDialog(dynamic item) {
    showDialog(
      context: context,
      builder: (_) => CatalogoFormDialog(
        title: 'Editar Categoría',
        fields: [
          CatalogoFieldConfig(key: 'nombre', label: 'Nombre', initialValue: item.nombre),
          CatalogoFieldConfig(key: 'descripcion', label: 'Descripción', initialValue: item.descripcion),
        ],
        onSubmit: (data) async {
          final token = ref.read(authProvider).token!;
          await ref.read(categoriasProvider.notifier).updateItem(token, item.id, data);
        },
      ),
    );
  }

  void _delete(int id) async {
    final token = ref.read(authProvider).token!;
    await ref.read(categoriasProvider.notifier).deleteItem(token, id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriasProvider);

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
                onIcon: const Icon(Icons.add),
                icon: const Icon(Icons.add),
                label: const Text('Agregar Categoría'),
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
                  DataColumn(label: Text('Descripción')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: state.items.map((item) => DataRow(
                  cells: [
                    DataCell(Text(item.id.toString())),
                    DataCell(Text(item.nombre)),
                    DataCell(Text(item.descripcion ?? '')),
                    DataCell(Icon(item.activo ? Icons.check_circle : Icons.cancel, color: item.activo ? Colors.green : Colors.red)),
                    DataCell(Row(
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditDialog(item)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(item.id)),
                      ],
                    )),
                  ],
                )).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
