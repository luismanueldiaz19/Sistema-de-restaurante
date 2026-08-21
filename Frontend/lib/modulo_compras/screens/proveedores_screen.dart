import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../providers/proveedores_provider.dart';
import '../models/proveedor.dart';
import 'widgets/add_proveedor_dialog.dart';

class ProveedoresScreen extends ConsumerStatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  ConsumerState<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends ConsumerState<ProveedoresScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proveedoresProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Proveedores', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AddProveedorDialog(),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(
              child: Text(
                'Error: ${state.error}',
                style: TextStyle(color: AppColors.danger),
              ),
            )
          : _buildList(state.proveedores),
    );
  }

  Widget _buildList(List<Proveedor> proveedores) {
    if (proveedores.isEmpty) {
      return const Center(
        child: Text(
          'No hay proveedores registrados.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: proveedores.length,
      itemBuilder: (context, index) {
        final proveedor = proveedores[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                proveedor.nombre[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              proveedor.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'RNC: ${proveedor.rnc ?? 'N/A'} | Tel: ${proveedor.telefono ?? 'N/A'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AddProveedorDialog(proveedor: proveedor),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: AppColors.danger),
                  onPressed: () => _confirmDelete(proveedor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(Proveedor proveedor) async {
    final bool? confirm = await CustomConfirmDialog.show(
      context,
      title: 'Eliminar Proveedor',
      message: '¿Está seguro de eliminar a ${proveedor.nombre}?',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      primaryColor: AppColors.danger,
    );

    if (confirm == true) {
      final success = await ref
          .read(proveedoresProvider.notifier)
          .deleteProveedor(proveedor.id);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Proveedor eliminado')));
      }
    }
  }
}
