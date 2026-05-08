import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modulo_cliente/models/cliente.dart';
import '../../modulo_cliente/providers/cliente_admin_provider.dart';
import '../../utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../models/factura_item.dart';
import '../providers/facturacion_provider.dart';
import '../services/facturacion_service.dart';
import '../models/producto_provisional.dart';
import '../widgets/panel_configuracion.dart';
import '../widgets/carrito_lista.dart';
import '../widgets/panel_totales.dart';
import 'widgets/buscador_cliente_dialog.dart';
import 'widgets/productos_widget.dart';
import '../../repositories/repo_comprobante.dart';
import '../../model/comprobante.dart';
import '../../palletes/app_colors.dart';
import '../providers/caja_provider.dart';
import 'apertura_caja_page.dart';
import 'arqueo_caja_page.dart';

class CrearFacturaPage extends ConsumerStatefulWidget {
  const CrearFacturaPage({super.key});

  @override
  ConsumerState<CrearFacturaPage> createState() => _CrearFacturaPageState();
}

class _CrearFacturaPageState extends ConsumerState<CrearFacturaPage> {
  final ComprobanteRepository _comprobanteRepo = ComprobanteRepository();
  final FacturacionService _facturaService = FacturacionService();
  List<Comprobante> _comprobantes = [];

  // Productos de prueba tipados
  final List<ProductoProvisional> _productosPrueba = [
    ProductoProvisional(
      id: "1",
      descripcion: "Pizza Familiar",
      precio: 850.0,
      stock: 10,
    ),
    ProductoProvisional(
      id: "2",
      descripcion: "Hamburguesa Doble",
      precio: 450.0,
      stock: 5,
    ),
    ProductoProvisional(
      id: "3",
      descripcion: "Coca Cola 2L",
      precio: 120.0,
      stock: 20,
    ),
    ProductoProvisional(
      id: "4",
      descripcion: "Papas Fritas",
      precio: 180.0,
      stock: 15,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final auth = ref.read(authProvider);
    final results = await _comprobanteRepo.getComprabante(auth.token!);
    setState(() => _comprobantes = results);
  }

  Future<void> _procesarVenta() async {
    final state = ref.read(facturacionProvider);
    final auth = ref.read(authProvider);

    if (state.clienteSeleccionado == null ||
        state.comprobanteSeleccionado == null) {
      showToast(
        context,
        'Seleccione cliente y comprobante',
        bgColor: Colors.orange,
      );
      return;
    }

    final result = await _facturaService.crearFactura(
      cliente: state.clienteSeleccionado!,
      comprobante: state.comprobanteSeleccionado!,
      items: state.carrito,
      token: auth.token!,
      userId: auth.user!.id!,
    );

    if (result['success'] && mounted) {
      showToast(context, 'Factura creada con éxito', bgColor: Colors.green);
      ref.read(facturacionProvider.notifier).limpiarCarrito();
      Navigator.pop(context);
    } else if (mounted) {
      showToast(context, result['message'], bgColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final factState = ref.watch(facturacionProvider);
    final factNotifier = ref.read(facturacionProvider.notifier);
    final clienteState = ref.watch(
      clienteAdminProvider,
    ); // 🔥 Restaurar esta línea

    // 🔥 CONTROL DE CAJA
    final cajaState = ref.watch(cajaProvider);

    if (cajaState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (cajaState.sesionActiva == null) {
      return const AperturaCajaPage();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vender',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${cajaState.sesionActiva!.nombreCaja} | ${cajaState.sesionActiva!.nombreTurno}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // Botón de Arqueo
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArqueoCajaPage()),
            ),
            icon: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
            ),
            label: const Text(
              'ARQUEO',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => factNotifier.limpiarCarrito(),
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            tooltip: 'Limpiar Carrito',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1000) {
            return const Center(
              child: Text(
                'Use una pantalla más grande para facturar (Mínimo 1024px)',
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📋 PANEL IZQUIERDO: CONFIGURACIÓN
              SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: PanelConfiguracion(
                    cliente: factState.clienteSeleccionado,
                    comprobante: factState.comprobanteSeleccionado,
                    comprobantes: _comprobantes,
                    onSelectCliente: () async {
                      final cliente = await showDialog<Cliente>(
                        context: context,
                        builder: (ctx) => BuscadorClienteDialog(
                          clientes: clienteState.clientes,
                        ),
                      );
                      if (cliente != null) {
                        factNotifier.seleccionarCliente(cliente);
                      }
                    },
                    onSelectComprobante: (c) =>
                        factNotifier.seleccionarComprobante(c!),
                  ),
                ),
              ),

              // 🍕 PANEL CENTRAL: CATÁLOGO
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: ProductosWidget(
                    productos: _productosPrueba,
                    articulos: [],
                    onUpdate: () {},
                    onProductTap: (prod) {
                      factNotifier.agregarProducto(
                        FacturaItem(
                          id: prod.id,
                          descripcion: prod.descripcion,
                          precio: prod.precio,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 🛒 PANEL DERECHO: CARRITO Y TOTALES
              SizedBox(
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: CarritoLista(
                          items: factState.carrito,
                          onUpdateCantidad: factNotifier.actualizarCantidad,
                          onRemove: factNotifier.removerProducto,
                        ),
                      ),
                      const SizedBox(height: 20),
                      PanelTotales(
                        totales: factState.totales,
                        isLoading: factState.isLoading,
                        onProcesar: _procesarVenta,
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
}
