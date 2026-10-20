import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../models/mesa_model.dart';
import '../providers/mesas_provider.dart';
import '../widgets/crear_editar_mesa_dialog.dart';
import '../widgets/mesa_areas_selector.dart';
import '../widgets/mesa_card_widget.dart';
import '../widgets/mesa_metrics_bar.dart';
import 'mesa_comanda_screen.dart';

class MesasScreen extends ConsumerStatefulWidget {
  const MesasScreen({super.key});

  @override
  ConsumerState<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends ConsumerState<MesasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mesasProvider).initPolling();
    });
  }

  Future<void> _abrirCrearEditarDialog({MesaModel? mesa}) async {
    if (!ref.read(authProvider).isAdmin) {
      showToast(
        context,
        'Solo un administrador del sistema puede gestionar mesas',
        bgColor: Colors.red,
      );
      return;
    }
    final provider = ref.read(mesasProvider);
    await showDialog(
      context: context,
      builder: (ctx) => CrearEditarMesaDialog(
        mesa: mesa,
        areasDisponibles: provider.areas,
        provider: provider,
      ),
    );
  }

  Future<void> _eliminarMesa(MesaModel mesa) async {
    if (!ref.read(authProvider).isAdmin) {
      showToast(
        context,
        'Solo un administrador del sistema puede eliminar mesas',
        bgColor: Colors.red,
      );
      return;
    }
    final confirm = await CustomConfirmDialog.show(
      context,
      title: 'Eliminar ${mesa.nombre}',
      message: '¿Estás seguro de que deseas eliminar esta mesa del sistema?',
      confirmText: 'Sí, Eliminar',
      cancelText: 'Cancelar',
      icon: Icons.delete_outline,
      primaryColor: AppColors.danger,
    );

    if (confirm == true) {
      try {
        await ref.read(mesasProvider).eliminarMesa(mesa.id);
        if (mounted) showToast(context, 'Mesa eliminada', bgColor: Colors.blue);
      } catch (e) {
        if (mounted) showToast(context, 'Error: $e', bgColor: Colors.red);
      }
    }
  }

  Future<void> _liberarMesa(MesaModel mesa) async {
    if (!ref.read(authProvider).isAdmin) {
      showToast(
        context,
        'Solo un administrador del sistema puede liberar mesas',
        bgColor: Colors.red,
      );
      return;
    }
    final confirm = await CustomConfirmDialog.show(
      context,
      title: 'Liberar ${mesa.nombre}',
      message:
          '¿Estás seguro de liberar esta mesa? La comanda activa se cerrará.',
      confirmText: 'Sí, Liberar',
      cancelText: 'Cancelar',
      icon: Icons.meeting_room_outlined,
      primaryColor: AppColors.danger,
    );

    if (confirm == true) {
      try {
        await ref.read(mesasProvider).liberarMesa(mesa.id);
        if (mounted) {
          showToast(context, '${mesa.nombre} liberada', bgColor: Colors.green);
        }
      } catch (e) {
        if (mounted) showToast(context, 'Error: $e', bgColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mesasProvider);
    final mesas = state.mesas;
    final totalConsumo = mesas.fold(0.0, (sum, m) => sum + m.totalConsumo);
    final isAdmin = ref.watch(authProvider).isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.secondary,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.table_restaurant,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Mesas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  'Gestión de comensales y comandas de servicio',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 19),
            tooltip: 'Actualizar mesas',
            onPressed: () => ref.read(mesasProvider).fetchMesas(),
          ),
          if (isAdmin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: () => _abrirCrearEditarDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Nueva Mesa',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Column(
        children: [
          // Barra de Métricas KPI
          MesaMetricsBar(state: state, totalConsumo: totalConsumo),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // Selector horizontal de Áreas
          MesaAreasSelector(state: state),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // Cuadrícula de Mesas
          Expanded(
            child: state.isLoading && mesas.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : mesas.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: mesas.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 210,
                          childAspectRatio: 1.05,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemBuilder: (ctx, i) {
                      final mesa = mesas[i];
                      return MesaCardWidget(
                        mesa: mesa,
                        isAdmin: isAdmin,
                        onOpenComanda: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MesaComandaScreen(mesaId: mesa.id),
                          ),
                        ),
                        onEditar: () => _abrirCrearEditarDialog(mesa: mesa),
                        onLiberar: () => _liberarMesa(mesa),
                        onEliminar: () => _eliminarMesa(mesa),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_restaurant_outlined,
            size: 44,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          const Text(
            'No hay mesas configuradas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Crea mesas para organizar el salón de tu restaurante.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _abrirCrearEditarDialog(),
            icon: const Icon(Icons.add, size: 15),
            label: const Text(
              'Crear Primera Mesa',
              style: TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
