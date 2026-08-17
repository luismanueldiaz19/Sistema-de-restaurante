import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/configuracion_contable_provider.dart';
import '../../model/catalogo_cuenta_model.dart';
import '../widgets/catalogo_cuenta_dialog.dart';

class CatalogoCuentasScreen extends ConsumerStatefulWidget {
  const CatalogoCuentasScreen({super.key});

  @override
  ConsumerState<CatalogoCuentasScreen> createState() => _CatalogoCuentasScreenState();
}

class _CatalogoCuentasScreenState extends ConsumerState<CatalogoCuentasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(configuracionContableProvider.notifier).loadAllData(token);
      }
    });
  }

  void _abrirDialogoCuenta([CatalogoCuentaModel? cuenta, CatalogoCuentaModel? cuentaPadre]) {
    showDialog(
      context: context,
      builder: (ctx) => CatalogoCuentaDialog(
        cuenta: cuenta,
        cuentaPadreDefault: cuentaPadre,
      ),
    );
  }

  void _eliminarCuenta(CatalogoCuentaModel cuenta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: Text('¿Estás seguro de eliminar la cuenta ${cuenta.codigo} - ${cuenta.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final token = ref.read(authProvider).token;
      if (token == null) return;
      try {
        await ref.read(configuracionContableProvider.notifier).eliminarCuenta(token, cuenta.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta eliminada')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  // Construye la lista jerárquica
  List<Widget> _buildTree(List<CatalogoCuentaModel> todas, int? padreId, int depth) {
    final hijos = todas.where((c) => c.padreId == padreId).toList();
    hijos.sort((a, b) => a.codigo.compareTo(b.codigo)); // Ordenar por código

    List<Widget> nodos = [];
    for (var hijo in hijos) {
      final tieneHijos = todas.any((c) => c.padreId == hijo.id);
      
      nodos.add(
        Padding(
          padding: EdgeInsets.only(left: depth * 24.0),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              leading: Icon(
                tieneHijos ? Icons.folder : Icons.insert_drive_file,
                color: tieneHijos ? AppColors.primary : Colors.grey.shade600,
              ),
              title: Text('${hijo.codigo} - ${hijo.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Tipo: ${hijo.tipo} | Nivel: ${hijo.nivel} | Transaccional: ${hijo.permiteMovimiento ? "Sí" : "No"}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    tooltip: 'Agregar Subcuenta',
                    onPressed: () => _abrirDialogoCuenta(null, hijo),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Editar',
                    onPressed: () => _abrirDialogoCuenta(hijo, null),
                  ),
                  if (!tieneHijos && hijo.nivel > 1)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Eliminar',
                      onPressed: () => _eliminarCuenta(hijo),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      // Llamada recursiva para los hijos
      if (tieneHijos) {
        nodos.addAll(_buildTree(todas, hijo.id, depth + 1));
      }
    }
    return nodos;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configuracionContableProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Catálogo de Cuentas'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: state.isLoading && state.catalogoCuentasCompleto.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.catalogoCuentasCompleto.isEmpty
              ? Center(child: Text('Error: ${state.errorMessage}'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _buildTree(state.catalogoCuentasCompleto, null, 0),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialogoCuenta(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Cuenta Raíz', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
