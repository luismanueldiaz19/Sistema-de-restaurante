import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../facturacion/services/printer_ticket_pedido.dart';
import '../../modulo_producto/models/producto.dart';
import '../../modulo_producto/providers/producto_provider.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../models/item_comanda_temp.dart';
import '../models/mesa_model.dart';
import '../providers/mesas_provider.dart';
import '../widgets/mesa_catalogo_panel.dart';
import '../widgets/mesa_comanda_actions.dart';
import '../widgets/mesa_ticket_panel.dart';

class MesaComandaScreen extends ConsumerStatefulWidget {
  final int mesaId;

  const MesaComandaScreen({super.key, required this.mesaId});

  @override
  ConsumerState<MesaComandaScreen> createState() => _MesaComandaScreenState();
}

class _MesaComandaScreenState extends ConsumerState<MesaComandaScreen> {
  final List<ItemComandaTemp> _nuevosItems = [];
  final TextEditingController _notaRondaController = TextEditingController();
  final TextEditingController _clienteNombreController =
      TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarProductos();
    });
  }

  void _cargarProductos() {
    final auth = ref.read(authProvider);
    if (auth.token != null) {
      ref
          .read(productoProvider.notifier)
          .loadProductos(auth.token!, search: '');
    }
  }

  @override
  void dispose() {
    _notaRondaController.dispose();
    _clienteNombreController.dispose();
    super.dispose();
  }

  void _agregarProducto(Producto prod) {
    final prodId = prod.id;
    if (prodId == null) return;

    setState(() {
      final index = _nuevosItems.indexWhere((it) => it.productoId == prodId);
      if (index != -1) {
        _nuevosItems[index].cantidad += 1;
      } else {
        _nuevosItems.add(
          ItemComandaTemp(
            productoId: prodId,
            nombre: prod.nombre ?? '',
            precio: prod.precioVenta ?? 0.0,
            cantidad: 1.0,
          ),
        );
      }
    });
  }

  void _cambiarCantidad(int index, double delta) {
    setState(() {
      _nuevosItems[index].cantidad += delta;
      if (_nuevosItems[index].cantidad <= 0) {
        _nuevosItems.removeAt(index);
      }
    });
  }

  Future<void> _enviarCocina(MesaModel mesa) async {
    if (_nuevosItems.isEmpty) return;

    setState(() => _isSaving = true);
    final provider = ref.read(mesasProvider);
    final detallesPayload = _nuevosItems.map((it) => it.toPayload()).toList();

    try {
      if (mesa.isLibre || mesa.ordenActiva == null) {
        final cliente = _clienteNombreController.text.trim();
        await provider.abrirMesa(mesa.id, {
          'cliente_nombre': cliente.isNotEmpty ? cliente : mesa.nombre,
          'cliente_telefono': '',
          'nota': _notaRondaController.text.trim(),
          'detalles': detallesPayload,
        });
        if (mounted) {
          showToast(
            context,
            '👨‍🍳 Comanda enviada a cocina. Mesa abierta.',
            bgColor: Colors.green,
          );
        }
      } else {
        await provider.agregarItems(mesa.id, {
          'detalles': detallesPayload,
          'nota': _notaRondaController.text.trim(),
        });
        if (mounted) {
          showToast(
            context,
            '👨‍🍳 Adición enviada a cocina con éxito',
            bgColor: Colors.green,
          );
        }
      }

      setState(() {
        _nuevosItems.clear();
        _notaRondaController.clear();
      });
    } catch (e) {
      if (mounted) showToast(context, 'Error: $e', bgColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _imprimirPrecuenta(MesaModel mesa) async {
    if (mesa.ordenActiva == null) {
      showToast(
        context,
        'La mesa no tiene consumos activos',
        bgColor: Colors.orange,
      );
      return;
    }

    try {
      final provider = ref.read(mesasProvider);
      await provider.solicitarCuenta(mesa.id);

      final printer = PedidoPrinterService.instance;
      final result = await printer.imprimirPedido(
        mesa.ordenActiva!,
        esCopia: true,
      );

      if (mounted) {
        if (result.exito) {
          showToast(
            context,
            '🖨️ Pre-cuenta impresa correctamente',
            bgColor: Colors.green,
          );
        } else {
          showToast(context, result.mensaje, bgColor: Colors.orange);
        }
      }
    } catch (e) {
      if (mounted) showToast(context, 'Error: $e', bgColor: Colors.red);
    }
  }

  Future<void> _liberarMesa(MesaModel mesa) async {
    final isAdmin = ref.read(authProvider).isAdmin;
    if (!isAdmin) {
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
          '¿Estás seguro de liberar esta mesa? Si hay una orden abierta se cerrará.',
      confirmText: 'Sí, Liberar',
      cancelText: 'Volver',
      icon: Icons.meeting_room_outlined,
      primaryColor: AppColors.danger,
    );

    if (confirm == true) {
      try {
        await ref.read(mesasProvider).liberarMesa(mesa.id);
        if (mounted) {
          showToast(context, '${mesa.nombre} liberada', bgColor: Colors.blue);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) showToast(context, 'Error: $e', bgColor: Colors.red);
      }
    }
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Libre':
        return Colors.green.shade700;
      case 'Ocupada':
        return Colors.orange.shade800;
      case 'PorCobrar':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mesasState = ref.watch(mesasProvider);
    final MesaModel mesa = mesasState.mesas.firstWhere(
      (m) => m.id == widget.mesaId,
      orElse: () => MesaModel(
        id: widget.mesaId,
        nombre: 'Mesa',
        area: 'Principal',
        capacidad: 4,
        estado: 'Libre',
      ),
    );

    final prodState = ref.watch(productoProvider);
    final statusColor = _getStatusColor(mesa.estado);

    final subtotalYaServido = mesa.ordenActiva?.total ?? 0.0;
    final subtotalNuevos = _nuevosItems.fold(
      0.0,
      (sum, it) => sum + it.subtotal,
    );
    final totalGeneral = subtotalYaServido + subtotalNuevos;

    final auth = ref.watch(authProvider);
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.secondary,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                mesa.nombre.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '• ${mesa.area} (${mesa.capacidad} pers.)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const Spacer(),
            Text(
              'Total: ${FormatterNumber.formatCurrency(totalGeneral)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PANEL IZQUIERDO: Catálogo de Productos
          Expanded(
            flex: 6,
            child: MesaCatalogoPanel(
              productos: prodState.productos,
              isLoading: prodState.isLoading,
              onSelectProducto: _agregarProducto,
              onReload: _cargarProductos,
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Color(0xFFE5E7EB),
          ),
          // PANEL DERECHO: Comanda viva y Acciones
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: MesaTicketPanel(
                    mesa: mesa,
                    nuevosItems: _nuevosItems,
                    clienteController: _clienteNombreController,
                    notaController: _notaRondaController,
                    onCambiarCantidad: _cambiarCantidad,
                  ),
                ),
                MesaComandaActions(
                  mesa: mesa,
                  totalGeneral: totalGeneral,
                  hasNuevosItems: _nuevosItems.isNotEmpty,
                  isSaving: _isSaving,
                  isAdmin: isAdmin,
                  onEnviarCocina: () => _enviarCocina(mesa),
                  onImprimirPrecuenta: () => _imprimirPrecuenta(mesa),
                  onLiberar: () => _liberarMesa(mesa),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
