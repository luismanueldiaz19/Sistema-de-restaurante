import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/modulo_producto/providers/producto_state.dart';
import '../../modulo_cliente/models/cliente.dart';
import '../../modulo_cliente/providers/cliente_admin_provider.dart';
import '../../modulo_producto/models/producto.dart';
import '../../modulo_producto/providers/producto_provider.dart';
import '../../utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../models/factura_item.dart';
import '../providers/facturacion_provider.dart';
import '../services/facturacion_service.dart';
import '../widgets/panel_configuracion.dart';
import '../widgets/carrito_lista.dart';
import '../widgets/pago_dialog.dart';
import '../widgets/panel_totales.dart';
import 'widgets/buscador_cliente_dialog.dart';
import '../../repositories/repo_comprobante.dart';
import '../../model/comprobante.dart';
import '../../palletes/app_colors.dart';
import '../../modulo_caja/providers/caja_provider.dart';
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
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final auth = ref.read(authProvider);

    // 1. Limpiar estado previo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(facturacionProvider.notifier).resetState();
    });

    // 2. Cargar comprobantes (Solo una vez al entrar)
    final results = await _comprobanteRepo.getComprabante(auth.token!);
    if (!mounted) return;
    setState(() => _comprobantes = results);

    // 3. Cargar clientes (Solo una vez al entrar)
    await ref.read(clienteAdminProvider.notifier).loadClients(auth.token!);

    // 4. Cargar productos (Carga inicial con spinner)
    await ref.read(productoProvider.notifier).loadProductos(auth.token!);

    // 5. Aplicar configuraciones por defecto
    _aplicarConfiguracionPorDefecto();
  }

  void _aplicarConfiguracionPorDefecto() {
    // Seleccionar comprobante de consumo por default
    final consumo = _comprobantes
        .where((c) => c.nombre.toLowerCase().contains('consumo'))
        .firstOrNull;
    if (consumo != null) {
      ref.read(facturacionProvider.notifier).seleccionarComprobante(consumo);
    }

    // Seleccionar cliente genérico por default
    final clients = ref.read(clienteAdminProvider).clientes;
    final generico = clients
        .where((c) => c.nombre!.toLowerCase().contains('generico'))
        .firstOrNull;
    if (generico != null) {
      ref.read(facturacionProvider.notifier).seleccionarCliente(generico);
    }
  }

  /// Reinicia la pantalla para la siguiente venta sin volver a pedir todo al servidor
  Future<void> _resetParaSiguienteVenta() async {
    final auth = ref.read(authProvider);

    // 1. Resetear el estado del proveedor (limpia carrito, etc)
    ref.read(facturacionProvider.notifier).resetState();

    // 2. Volver a aplicar cliente y comprobante por defecto (usando los datos ya cargados)
    _aplicarConfiguracionPorDefecto();

    // 3. Opcional: Actualizar stock de productos en segundo plano (silencioso)
    ref.read(productoProvider.notifier).loadProductos(auth.token!, silent: true);
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

    if (state.carrito.isEmpty) {
      showToast(context, 'El carrito está vacío', bgColor: Colors.orange);
      return;
    }

    Map<String, dynamic>? pagoInfo;

    // Si es al contado, pedir el pago primero
    if (state.tipoFactura == 'contado') {
      pagoInfo = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PagoDialog(total: state.totales.total),
      );

      // Si cancela el diálogo, no procesar factura
      if (pagoInfo == null) return;
    }

    final result = await _facturaService.crearFactura(
      cliente: state.clienteSeleccionado!,
      comprobante: state.comprobanteSeleccionado!,
      items: state.carrito,
      token: auth.token!,
      userId: auth.user!.id!,
      tipoFactura: state.tipoFactura,
      diasCredito: state.diasCredito,
      nota: state.nota,
      pago: pagoInfo,
    );

    if (result['success'] && mounted) {
      showToast(context, 'Factura creada con éxito', bgColor: Colors.green);
      // En lugar de recargar todo, solo reseteamos localmente
      _resetParaSiguienteVenta();
    } else if (mounted) {
      showToast(context, result['message'], bgColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final factState = ref.watch(facturacionProvider);
    final factNotifier = ref.read(facturacionProvider.notifier);
    final clienteState = ref.watch(clienteAdminProvider);
    final prodState = ref.watch(productoProvider);
    final cajaState = ref.watch(cajaProvider);

    if (cajaState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (cajaState.sesionActiva == null) {
      return const AperturaCajaPage();
    }

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Punto de Venta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
              ),
            ),
            Text(
              '${cajaState.sesionActiva?['caja']?['nombre'] ?? '...'} | ${cajaState.sesionActiva?['turno']?['nombre'] ?? '...'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          const SizedBox(width: 12),
          _buildCircleButton(
            icon: Icons.delete_sweep_outlined,
            color: Colors.redAccent,
            onTap: () => factNotifier.limpiarCarrito(),
            tooltip: 'Limpiar Carrito',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth < 1100;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📋 PANEL IZQUIERDO: CONFIGURACIÓN (Solo en Desktop)
              if (!isTablet)
                SizedBox(
                  width: 320,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: PanelConfiguracion(
                      cliente: factState.clienteSeleccionado,
                      comprobante: factState.comprobanteSeleccionado,
                      comprobantes: _comprobantes,
                      tipoFactura: factState.tipoFactura,
                      diasCredito: factState.diasCredito,
                      nota: factState.nota,
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
                      onCambiarTipo: factNotifier.cambiarTipoFactura,
                      onCambiarDias: factNotifier.cambiarDiasCredito,
                      onCambiarNota: factNotifier.cambiarNota,
                    ),
                  ),
                ),

              // 🍕 PANEL CENTRAL: CATÁLOGO (Adaptable)
              Expanded(
                child: Column(
                  children: [
                    if (isTablet)
                      _buildCompactConfigHeader(
                        factState,
                        factNotifier,
                        clienteState,
                      ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        child: _buildProductCatalog(prodState, factNotifier),
                      ),
                    ),
                  ],
                ),
              ),

              // 🛒 PANEL DERECHO: CARRITO Y TOTALES
              SizedBox(
                width: isTablet ? 340 : 400,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 24, 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
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
                            items: factState.carrito,
                            onUpdateCantidad: factNotifier.actualizarCantidad,
                            onRemove: factNotifier.removerProducto,
                          ),
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

  Widget _buildCompactConfigHeader(
    FacturacionState factState,
    FacturacionNotifier factNotifier,
    dynamic clienteState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactSelector(
              icon: Icons.person_outline,
              label:
                  factState.clienteSeleccionado?.nombre ??
                  'Seleccionar Cliente',
              onTap: () async {
                final cliente = await showDialog<Cliente>(
                  context: context,
                  builder: (ctx) =>
                      BuscadorClienteDialog(clientes: clienteState.clientes),
                );
                if (cliente != null) factNotifier.seleccionarCliente(cliente);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactSelector(
              icon: Icons.payments_outlined,
              label: factState.tipoFactura == 'contado' ? 'Contado' : 'Crédito',
              onTap: () {
                final cliente = factState.clienteSeleccionado;
                if (cliente != null && (cliente.diasCredito ?? 0) > 0) {
                  final nuevoTipo = factState.tipoFactura == 'contado'
                      ? 'credito'
                      : 'contado';
                  factNotifier.cambiarTipoFactura(nuevoTipo);
                } else {
                  showToast(
                    context,
                    'Este cliente no tiene crédito habilitado',
                    bgColor: Colors.orange,
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactSelector(
              icon: Icons.receipt_long_outlined,
              label: factState.comprobanteSeleccionado?.nombre ?? 'Comprobante',
              onTap: () {
                // TODO: Implement quick select for comprobante on tablet
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSelector({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCatalog(
    ProductoState prodState,
    FacturacionNotifier factNotifier,
  ) {
    if (prodState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final filteredProducts = prodState.productos.where((p) {
      final name = p.nombre?.toLowerCase() ?? "";
      return name.contains(_searchQuery.toLowerCase());
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
                      hintText: 'Buscar producto por nombre o código...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildCircleButton(
                icon: Icons.filter_list,
                color: AppColors.secondary,
                onTap: () {},
                tooltip: 'Filtrar',
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? _buildEmptyState()
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
                    return _buildProductCard(prod, factNotifier);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Producto prod, FacturacionNotifier factNotifier) {
    return InkWell(
      onTap: () {
        factNotifier.agregarProducto(
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
                          'S: ${prod.stockActual?.toInt() ?? 0}',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'No se encontraron productos',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: AppColors.primary, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
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
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
