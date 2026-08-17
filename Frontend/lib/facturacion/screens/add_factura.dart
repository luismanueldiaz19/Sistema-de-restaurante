import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/modulo_producto/providers/producto_state.dart';
import '../../modulo_cliente/models/cliente.dart';
import '../../modulo_cliente/providers/cliente_admin_provider.dart';
import '../../modulo_producto/models/producto.dart';
import '../../modulo_producto/providers/producto_provider.dart';
import '../../utils/helpers.dart';
import '../../model/company.dart';
import '../../providers/auth_provider.dart';
import '../models/factura_item.dart';
import '../providers/facturacion_provider.dart';
import '../services/facturacion_service.dart';
import '../../pedidos/services/pedido_service.dart';
import '../services/printer_service.dart';
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

class CrearFacturaPage extends ConsumerStatefulWidget {
  const CrearFacturaPage({super.key});

  @override
  ConsumerState<CrearFacturaPage> createState() => _CrearFacturaPageState();
}

class _CrearFacturaPageState extends ConsumerState<CrearFacturaPage> {
  final ComprobanteRepository _comprobanteRepo = ComprobanteRepository();
  final FacturacionService _facturaService = FacturacionService();
  final PedidoService _pedidoService = PedidoService();
  final ThermalPrinterService _printer = ThermalPrinterService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Comprobante> _comprobantes = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeScan(
    String codigo,
    FacturacionNotifier factNotifier,
  ) async {
    if (codigo.trim().isEmpty) return;

    if (codigo.trim().length >= 10 &&
        RegExp(r'^\d+$').hasMatch(codigo.trim())) {
      try {
        final pedido = await _pedidoService.getPedidoByCodigo(codigo.trim());
        if (pedido != null) {
          factNotifier.limpiarCarrito();
          for (var detalle in pedido.detalles) {
            factNotifier.agregarProducto(
              FacturaItem(
                id: detalle.productoId.toString(),
                descripcion: detalle.nombreProducto,
                precio: detalle.precioUnitario,
                cantidad: detalle.cantidad,
              ),
            );
          }
          if (mounted) {
            showToast(
              context,
              'Pedido #${pedido.secuenciaDiaria} cargado',
              bgColor: Colors.green,
            );
            setState(() {
              _searchQuery = '';
              _searchController.clear();
            });
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          showToast(context, 'No se encontró pedido', bgColor: Colors.orange);
        }
      }
    }
  }

  Future<void> _initData() async {
    final auth = ref.read(authProvider);

    // 1. Limpiar estado previo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(facturacionProvider.notifier).resetState();
    });

    // 2. Cargar comprobantes (Solo una vez al entrar)
    final results = await _comprobanteRepo.getComprabante(auth.token!);
    final validSalesNcf = results.where((c) {
      // 31: Crédito Fiscal, 32: Consumo, 44: Régimen Especial, 45: Gubernamental, 46: Exportaciones
      return [
        '31',
        '32',
        '44',
        '45',
        '46',
      ].contains(c.tipo.replaceAll(RegExp(r'[^0-9]'), ''));
    }).toList();
    setState(() => _comprobantes = validSalesNcf);

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
    ref
        .read(productoProvider.notifier)
        .loadProductos(auth.token!, silent: true);
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
      // showToast(context, 'Factura creada con éxito', bgColor: Colors.green);
      // 🖨️ Imprimir ticket en impresora térmica USB (no bloquea el flujo)
      _imprimirTicket(state, result['data'], pagoInfo);
      // Resetear para la siguiente venta
      _resetParaSiguienteVenta();
    } else if (mounted) {
      showToast(context, result['message'], bgColor: Colors.red);
    }
  }

  /// Imprime el ticket de la factura recién creada.
  /// Se ejecuta de forma asíncrona sin bloquear la UI.
  Future<void> _imprimirTicket(
    FacturacionState state,
    Map<String, dynamic>? facturaData,
    Map<String, dynamic>? pagoInfo,
  ) async {
    // Construir número de factura desde la respuesta del servidor

    final resultado = await _printer.imprimirFactura(
      nombreNegocio: Company.current.nombre,
      direccion: Company.current.direccionCompleta,
      rncOCedula: Company.current.rnc,
      numeroFactura: facturaData?['factura_id']?.toString() ?? 'S/N',
      ncf: facturaData?['ncf']?.toString(),
      fecha: DateTime.now(),
      items: state.carrito
          .map(
            (item) => ItemFactura(
              descripcion: item.descripcion,
              cantidad: item.cantidad,
              precioUnitario: item.precio,
            ),
          )
          .toList(),
      subtotal: state.totales.subtotal,
      impuesto: state.totales.itbis,
      descuento: state.totales.descuento,
      total: state.totales.total,
      cliente: state.clienteSeleccionado?.nombre,
      rncCliente: state.clienteSeleccionado?.rncCedula,
      nota: state.nota.isNotEmpty ? state.nota : null,
      tipoPago: state.tipoFactura == 'contado' ? 'CONTADO' : 'CREDITO',
      metodoPago: pagoInfo?['metodo_pago']?.toString().toUpperCase(),
      montoRecibido: pagoInfo?['monto_recibido'],
      devuelta: pagoInfo?['devuelta'],
    );

    if (!resultado.exito && mounted) {
      // Aviso no bloqueante — la factura ya se guardó en el servidor
      showToast(
        context,
        '🖨️ ${resultado.mensaje}',
        bgColor: Colors.orange.shade700,
      );
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
          // 🖨️ Botón de prueba de impresora
          _buildCircleButton(
            icon: Icons.print_outlined,
            color: Colors.teal,
            tooltip: 'Probar Impresora',
            onTap: () async {
              final resultado = await _printer.imprimirPrueba();

              if (mounted) {
                showToast(
                  context,
                  resultado.mensaje,
                  bgColor: resultado.exito
                      ? Colors.teal
                      : Colors.orange.shade700,
                );
              }
            },
          ),
          const SizedBox(width: 8),
          _buildCircleButton(
            icon: Icons.delete_sweep_outlined,
            color: Colors.redAccent,
            onTap: () => factNotifier.limpiarCarrito(),
            tooltip: 'Limpiar Carrito',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📋 PANEL IZQUIERDO: CONFIGURACIÓN
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
                    builder: (ctx) =>
                        BuscadorClienteDialog(clientes: clienteState.clientes),
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

          // 🍕 PANEL CENTRAL: CATÁLOGO
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
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

          // 🛒 PANEL DERECHO: CARRITO Y TOTALES
          SizedBox(
            width: 380,
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
                    carrito: factState.carrito,
                    onProcesar: _procesarVenta,
                  ),
                ],
              ),
            ),
          ),
        ],
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
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    onSubmitted: (v) => _handleBarcodeScan(v, factNotifier),
                    decoration: const InputDecoration(
                      hintText:
                          'Buscar producto o escanear ticket de pedido...',
                      border: InputBorder.none,
                      icon: Icon(Icons.qr_code_scanner, color: Colors.grey),
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
            itbisPorcentaje: prod.impuesto?.tasa ?? 0.0,
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
