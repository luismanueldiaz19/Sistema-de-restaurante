import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modulo_producto/models/producto.dart';
import '../../modulo_producto/providers/producto_provider.dart';
import '../../modulo_producto/providers/producto_state.dart';
import '../../utils/helpers.dart';
import '../../palletes/app_colors.dart';
import '../../facturacion/models/factura_item.dart';
import '../../facturacion/widgets/carrito_lista.dart';
import '../../facturacion/widgets/panel_totales.dart';
import '../providers/crear_pedido_provider.dart';
import '../services/pedido_service.dart';
import '../../providers/auth_provider.dart';
import '../models/pedido.dart';
import '../../facturacion/services/printer_ticket_pedido.dart';

class CrearPedidoPage extends ConsumerStatefulWidget {
  const CrearPedidoPage({super.key});

  @override
  ConsumerState<CrearPedidoPage> createState() => _CrearPedidoPageState();
}

class _CrearPedidoPageState extends ConsumerState<CrearPedidoPage> {
  final PedidoService _pedidoService = PedidoService();
  String _searchQuery = "";

  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _notaController = TextEditingController();
  String _tipoEntrega = 'Delivery';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(crearPedidoProvider.notifier).resetState();

      final auth = ref.read(authProvider);
      if (auth.token != null) {
        ref.read(productoProvider.notifier).loadProductos(auth.token!);
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  void _actualizarInfoCliente() {
    ref
        .read(crearPedidoProvider.notifier)
        .setClienteInfo(
          nombre: _nombreController.text,
          telefono: _telefonoController.text,
          direccion: _direccionController.text,
          tipoEntrega: _tipoEntrega,
          nota: _notaController.text,
        );
  }

  Future<void> _procesarPedido() async {
    _actualizarInfoCliente();
    final state = ref.read(crearPedidoProvider);

    if (state.clienteNombre.isEmpty) {
      showToast(
        context,
        'Ingrese el nombre del cliente',
        bgColor: Colors.orange,
      );
      return;
    }

    if (state.carrito.isEmpty) {
      showToast(context, 'El carrito está vacío', bgColor: Colors.orange);
      return;
    }

    final detalles = state.carrito
        .map(
          (item) => {
            'producto_id': int.tryParse(item.id) ?? 0,
            'cantidad': item.cantidad,
            'precio_unitario': item.precio,
            'subtotal': item.subtotal,
          },
        )
        .toList();

    final now = DateTime.now();
    final fechaLocal =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final payload = {
      'fecha': fechaLocal,
      'cliente_nombre': state.clienteNombre,
      'cliente_telefono': state.clienteTelefono,
      'direccion': state.direccion,
      'tipo_entrega': state.tipoEntrega,
      'nota': state.nota,
      'total': state.totales.total,
      'detalles': detalles,
    };

    try {
      final result = await _pedidoService.crearPedido(payload);
      if (result['success'] && mounted) {
        print('=== INICIANDO IMPRESIÓN AUTOMÁTICA ===');
        print(
          'Contenido de result["data"]: ${result['data'] != null ? "EXISTE" : "ES NULL"}',
        );

        if (result['data'] != null) {
          try {
            print('Parseando JSON del pedido...');
            final nuevoPedido = Pedido.fromJson(result['data']);
            print('Pedido parseado correctamente. ID: ${nuevoPedido.id}');

            print('Llamando al servicio de impresión...');
            final printResult = await PedidoPrinterService.instance
                .imprimirPedido(nuevoPedido);
            print(
              'Resultado de impresión: exito=${printResult.exito}, mensaje=${printResult.mensaje}',
            );

            if (!printResult.exito && mounted) {
              showToast(
                context,
                'Impresión falló: ${printResult.mensaje}',
                bgColor: Colors.orange,
              );
            }
          } catch (e, stack) {
            print('=== ERROR EN IMPRESIÓN AUTOMÁTICA ===');
            print('Excepción: $e');
            print('StackTrace: $stack');
          }
        }

        showToast(context, 'Pedido creado exitosamente', bgColor: Colors.green);
        Navigator.pop(context, true);
      } else if (mounted) {
        showToast(context, result['message'], bgColor: Colors.red);
      }
    } catch (e, stack) {
      print('===== ERROR EXCEPCION AL CREAR PEDIDO =====');
      print(e);
      print(stack);
      if (mounted) {
        showToast(context, 'Error al crear pedido: $e', bgColor: Colors.red);
      }
    }
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedState = ref.watch(crearPedidoProvider);
    final pedNotifier = ref.read(crearPedidoProvider.notifier);
    final prodState = ref.watch(productoProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Crear Nuevo Pedido',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.secondary,
          ),
        ),
        actions: [
          _buildCircleButton(
            icon: Icons.delete_sweep_outlined,
            color: Colors.redAccent,
            onTap: () => pedNotifier.limpiarCarrito(),
            tooltip: 'Limpiar Carrito',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PANEL IZQUIERDO: CONFIGURACIÓN
              SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'DATOS DEL CLIENTE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const _Label(text: 'NOMBRE *'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nombreController,
                          hintText: 'Ej. Juan Pérez',
                        ),
                        const SizedBox(height: 16),

                        const _Label(text: 'TELÉFONO'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _telefonoController,
                          hintText: 'Ej. 809-555-5555',
                        ),
                        const SizedBox(height: 16),

                        const _Label(text: 'DIRECCIÓN'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _direccionController,
                          hintText: 'Ej. Calle Principal #123',
                          maxLines: 2,
                        ),

                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'DETALLES DEL PEDIDO',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const _Label(text: 'TIPO DE ENTREGA'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              value: _tipoEntrega,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey,
                              ),
                              items: ['Delivery', 'Recoger'].map((
                                String value,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _tipoEntrega = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const _Label(text: 'NOTAS ADICIONALES'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _notaController,
                          hintText: 'Ej. Sin cebolla, etc.',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // PANEL CENTRAL: CATÁLOGO
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _buildProductCatalog(prodState, pedNotifier),
                      ),
                    ),
                  ],
                ),
              ),

              // PANEL DERECHO: CARRITO Y TOTALES
              SizedBox(
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CarritoLista(
                            items: pedState.carrito,
                            onUpdateCantidad: pedNotifier.actualizarCantidad,
                            onRemove: pedNotifier.removerProducto,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PanelTotales(
                        totales: pedState.totales,
                        isLoading: pedState.isLoading,
                        esPedido: true,
                        onProcesar: _procesarPedido,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCatalog(
    ProductoState prodState,
    CrearPedidoNotifier pedNotifier,
  ) {
    if (prodState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    String normalize(String text) => text.trim().toLowerCase();
    final normalizeQuery = normalize(_searchQuery.toString());

    final filteredProducts = prodState.productos.where((p) {
      if (p.tipoProducto == 'MATERIA_PRIMA') return false;
      final name = p.nombre;
      return normalize(name ?? '').contains(normalizeQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto por nombre...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(child: Text("No se encontraron productos"))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final prod = filteredProducts[index];
                    return _buildProductCard(prod, pedNotifier);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Producto prod, CrearPedidoNotifier pedNotifier) {
    return InkWell(
      onTap: () {
        pedNotifier.agregarProducto(
          FacturaItem(
            id: prod.id.toString(),
            descripcion: prod.nombre ?? 'Sin nombre',
            precio: prod.precioVenta ?? 0,
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.fastfood_outlined,
                    size: 48,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prod.nombre ?? 'Sin nombre',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatCurrency(prod.precioVenta ?? 0),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'S: --',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade400,
        letterSpacing: 0.5,
      ),
    );
  }
}
