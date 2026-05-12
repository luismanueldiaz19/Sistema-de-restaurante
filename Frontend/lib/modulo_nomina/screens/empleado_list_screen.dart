import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/utils/helpers.dart';
import '../../palletes/app_colors.dart';
import '../models/empleado_model.dart';
import '../providers/nomina_provider.dart';
import 'empleado_form_screen.dart';

class EmpleadoListScreen extends ConsumerStatefulWidget {
  const EmpleadoListScreen({super.key});

  @override
  ConsumerState<EmpleadoListScreen> createState() => _EmpleadoListScreenState();
}

class _EmpleadoListScreenState extends ConsumerState<EmpleadoListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nominaProvider.notifier).fetchAllEmpleados();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nominaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Empleados'),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.empleados.isEmpty
          ? const Center(child: Text('No hay empleados registrados.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.empleados.length,
              itemBuilder: (context, index) {
                final empleado = state.empleados[index];
                return _EmpleadoTile(empleado: empleado);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (_) => const EmpleadoFormDialog(),
          );

          if (result == true && context.mounted) {
            ref.read(nominaProvider.notifier).fetchAllEmpleados();
          }
        },
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo Empleado'),
      ),
    );
  }
}

class _EmpleadoTile extends ConsumerWidget {
  final EmpleadoModel empleado;

  const _EmpleadoTile({required this.empleado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: empleado.activo
              ? Colors.green.shade100
              : Colors.grey.shade200,
          child: Icon(
            Icons.person_outline,
            color: empleado.activo ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          empleado.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: empleado.activo ? null : TextDecoration.lineThrough,
            color: empleado.activo ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          '${empleado.cargo ?? "Sin cargo"} • ${formatCurrency(empleado.salarioBase)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: empleado.activo,
              onChanged: (_) {
                ref
                    .read(nominaProvider.notifier)
                    .toggleEmpleadoStatus(empleado.id!);
              },
              activeColor: AppColors.success,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (_) => EmpleadoFormDialog(empleado: empleado),
                );

                if (result == true && context.mounted) {
                  ref.read(nominaProvider.notifier).fetchAllEmpleados();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
