import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../providers/ingrediente_provider.dart';
import '../widgets/add_ingrediente_dialog.dart';

class ScreenIngredientes extends ConsumerStatefulWidget {
  const ScreenIngredientes({super.key});

  @override
  ConsumerState<ScreenIngredientes> createState() => _ScreenIngredientesState();
}

class _ScreenIngredientesState extends ConsumerState<ScreenIngredientes> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      ref.read(ingredienteProvider.notifier).fetchIngredientes(auth.token!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ingredientes = ref.watch(ingredienteProvider);
    final auth = ref.watch(authProvider);
    final isAdmin = auth.roles.contains('admin');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Gestión de Ingredientes (Materia Prima)',
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          if (auth.hasPermission('crear_inventario'))
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => _openAddDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Ingrediente'),
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
      body: ingredientes.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      Colors.blueGrey.shade50,
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Nombre',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Unidad',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Stock Actual',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Costo Unitario',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Costo Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Acciones',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: ingredientes.map((i) {
                      return DataRow(
                        cells: [
                          DataCell(Text(i.nombre)),
                          DataCell(Text(i.unidad ?? '-')),
                          DataCell(
                            Text(
                              '${i.stock}',
                              style: TextStyle(
                                color: i.stock < 5 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text('\$${i.costoUnitario}')),
                          DataCell(
                            Text(
                              '\$${(i.stock * i.costoUnitario).toStringAsFixed(2)}',
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
                                  onPressed: () =>
                                      _openAddDialog(ingrediente: i),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(i.id.toString()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ingredientes registrados',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Comienza agregando los ingredientes base de tu cocina'),
        ],
      ),
    );
  }

  void _openAddDialog({dynamic ingrediente}) {
    showDialog(
      context: context,
      builder: (_) => AddIngredienteDialog(ingrediente: ingrediente),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Ingrediente'),
        content: const Text(
          '¿Estás seguro de eliminar este ingrediente? Esto podría afectar las recetas asociadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final auth = ref.read(authProvider);
              final success = await ref
                  .read(ingredienteProvider.notifier)
                  .deleteIngrediente(id, auth.token!);
              if (success && mounted) Navigator.pop(context);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
