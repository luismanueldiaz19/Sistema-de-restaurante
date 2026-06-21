import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/modulo_producto/providers/producto_state.dart';
import '../../modulo_cliente/models/cliente.dart';
import '../../modulo_cliente/providers/cliente_admin_provider.dart';
import '../../modulo_producto/models/producto.dart';
import '../../modulo_producto/providers/producto_provider.dart';
import '../../utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../facturacion/models/factura_item.dart';
import '../providers/cotizacion_form_provider.dart';
import '../../facturacion/widgets/carrito_lista.dart';
import '../../facturacion/widgets/panel_totales.dart';
import '../../facturacion/screens/widgets/buscador_cliente_dialog.dart';
import '../../palletes/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class CrearCotizacionScreen extends ConsumerStatefulWidget {
  const CrearCotizacionScreen({super.key});

  @override
  ConsumerState<CrearCotizacionScreen> createState() =>
      _CrearCotizacionScreenState();
}

class _CrearCotizacionScreenState extends ConsumerState<CrearCotizacionScreen> {
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final auth = ref.read(authProvider);

    Future.microtask(() async {
      ref.read(cotizacionFormProvider.notifier).resetState();
      await ref.read(clienteAdminProvider.notifier).loadClients(auth.token!);
      await ref.read(productoProvider.notifier).loadProductos(auth.token!);
      _aplicarConfiguracionPorDefecto();
    });
  }

  void _aplicarConfiguracionPorDefecto() {
    final clients = ref.read(clienteAdminProvider).clientes;
    final generico = clients
        .where((c) => c.nombre!.toLowerCase().contains('generico'))
        .firstOrNull;
    if (generico != null) {
      ref.read(cotizacionFormProvider.notifier).seleccionarCliente(generico);
    }
  }

  Future<void> _procesarCotizacion() async {
    final auth = ref.read(authProvider);
    final result = await ref
        .read(cotizacionFormProvider.notifier)
        .crearCotizacion(auth.token!);

    if (result['success'] && mounted) {
      showToast(context, 'Cotización creada con éxito', bgColor: Colors.green);

      final cotizacionId = result['data']['cotizacion_id'];
      if (cotizacionId != null) {
        final urlWithToken = Uri.parse(
          "$hostName/api/cotizaciones/$cotizacionId/pdf",
        );
        if (await canLaunchUrl(urlWithToken)) {
          await launchUrl(urlWithToken, mode: LaunchMode.externalApplication);
        }
      }

      ref.read(cotizacionFormProvider.notifier).resetState();
      _aplicarConfiguracionPorDefecto();
    } else if (mounted) {
      showToast(context, result['message'], bgColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(cotizacionFormProvider);
    final formNotifier = ref.read(cotizacionFormProvider.notifier);
    final clienteState = ref.watch(clienteAdminProvider);
    final prodState = ref.watch(productoProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Nueva Cotización',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.secondary,
          ),
        ),
        actions: [
          const SizedBox(width: 12),
          _buildCircleButton(
            icon: Icons.delete_sweep_outlined,
            color: Colors.redAccent,
            onTap: () => formNotifier.limpiarCarrito(),
            tooltip: 'Limpiar Cotización',
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
              // PANEL CENTRAL: CATÁLOGO
              Expanded(
                child: Column(
                  children: [
                    _buildConfigHeader(formState, formNotifier, clienteState),
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
                        child: _buildProductCatalog(prodState, formNotifier),
                      ),
                    ),
                  ],
                ),
              ),

              // PANEL DERECHO: CARRITO Y TOTALES
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
                            items: formState.carrito,
                            onUpdateCantidad: formNotifier.actualizarCantidad,
                            onRemove: formNotifier.removerProducto,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PanelTotales(
                        totales: formState.totales,
                        isLoading: formState.isLoading,
                        onProcesar: _procesarCotizacion,
                        esCotizacion: true,
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

  Widget _buildConfigHeader(
    CotizacionFormState state,
    CotizacionFormNotifier notifier,
    dynamic clienteState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildCompactSelector(
              icon: Icons.person_outline,
              label: state.clienteSeleccionado?.nombre ?? 'Seleccionar Cliente',
              onTap: () async {
                final cliente = await showDialog<Cliente>(
                  context: context,
                  builder: (ctx) =>
                      BuscadorClienteDialog(clientes: clienteState.clientes),
                );
                if (cliente != null) notifier.seleccionarCliente(cliente);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: _buildCompactSelector(
              icon: Icons.date_range,
              label: '${state.diasValidez} días de validez',
              onTap: () async {
                String val = state.diasValidez.toString();
                final result = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: const Text('Días de Validez'),
                      content: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (v) => val = v,
                        decoration: const InputDecoration(hintText: 'Ej. 15'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, null),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, val),
                          child: const Text('Guardar'),
                        ),
                      ],
                    );
                  },
                );
                if (result != null && int.tryParse(result) != null) {
                  notifier.cambiarDiasValidez(int.parse(result));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildCompactSelector(
              icon: Icons.note_alt_outlined,
              label: state.nota.isEmpty ? 'Añadir Nota' : state.nota,
              onTap: () async {
                String val = state.nota;
                final result = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: const Text('Nota de Cotización'),
                      content: TextField(
                        onChanged: (v) => val = v,
                        decoration: const InputDecoration(
                          hintText: 'Comentarios adicionales...',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, null),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, val),
                          child: const Text('Guardar'),
                        ),
                      ],
                    );
                  },
                );
                if (result != null) {
                  notifier.cambiarNota(result);
                }
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
    CotizacionFormNotifier formNotifier,
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
                      hintText: 'Buscar producto...',
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
                    return _buildProductCard(prod, formNotifier);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Producto prod, CotizacionFormNotifier formNotifier) {
    return InkWell(
      onTap: () {
        formNotifier.agregarProducto(
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
                    Icons.inventory_2_outlined,
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
                  Text(
                    formatCurrency(prod.precioVenta ?? 0),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
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
