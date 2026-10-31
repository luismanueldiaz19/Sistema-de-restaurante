import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/catalogo_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/catalogo_form_dialog.dart';

class UnidadMedidaTab extends ConsumerStatefulWidget {
  const UnidadMedidaTab({super.key});

  @override
  ConsumerState<UnidadMedidaTab> createState() => _UnidadMedidaTabState();
}

class _UnidadMedidaTabState extends ConsumerState<UnidadMedidaTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(unidadesProvider.notifier).fetchAll(token);
      }
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => CatalogoFormDialog(
        title: 'Nueva Unidad de Medida',
        fields: [
          CatalogoFieldConfig(key: 'nombre', label: 'Nombre'),
          CatalogoFieldConfig(key: 'abreviatura', label: 'Abreviatura'),
        ],
        onSubmit: (data) async {
          final token = ref.read(authProvider).token!;
          await ref.read(unidadesProvider.notifier).create(token, data);
        },
      ),
    );
  }

  void _showEditDialog(dynamic item) {
    showDialog(
      context: context,
      builder: (_) => CatalogoFormDialog(
        title: 'Editar Unidad de Medida',
        fields: [
          CatalogoFieldConfig(key: 'nombre', label: 'Nombre', initialValue: item.nombre),
          CatalogoFieldConfig(key: 'abreviatura', label: 'Abreviatura', initialValue: item.abreviatura),
        ],
        onSubmit: (data) async {
          final token = ref.read(authProvider).token!;
          await ref.read(unidadesProvider.notifier).updateItem(token, item.id, data);
        },
      ),
    );
  }

  void _delete(int id) async {
    final token = ref.read(authProvider).token!;
    await ref.read(unidadesProvider.notifier).deleteItem(token, id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unidadesProvider);

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
                label: const Text('Agregar Unidad de Medida'),
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
                  DataColumn(label: Text('Abreviatura')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: state.items.map((item) => DataRow(
                  cells: [
                    DataCell(Text(item.id.toString())),
                    DataCell(Text(item.nombre)),
                    DataCell(Text(item.abreviatura ?? '')),
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
