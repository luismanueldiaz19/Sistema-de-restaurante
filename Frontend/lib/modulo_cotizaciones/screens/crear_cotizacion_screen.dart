import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/modulo_producto/providers/producto_state.dart';
import 'package:sistema_restaurante/utils/normalize.dart';
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
      await ref
          .read(productoProvider.notifier)
          .loadProductos(auth.token!, search: '');
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

      final pdfUrlPath = result['data']['pdf_url'];
      if (pdfUrlPath != null) {
        final urlToLaunch = Uri.parse("$hostName$pdfUrlPath");
        if (await canLaunchUrl(urlToLaunch)) {
          await launchUrl(urlToLaunch, mode: LaunchMode.externalApplication);
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
            fontSize: 16,
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📋 PANEL IZQUIERDO: CONFIGURACIÓN
          SizedBox(
            width: 260,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: _buildLeftPanelConfig(
                formState,
                formNotifier,
                clienteState,
              ),
            ),
          ),

          // 🍕 PANEL CENTRAL: CATÁLOGO
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _buildProductCatalog(prodState, formNotifier),
            ),
          ),

          // 🛒 PANEL DERECHO: CARRITO Y TOTALES
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
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
                  const SizedBox(height: 8),
                  PanelTotales(
                    totales: formState.totales,
                    isLoading: formState.isLoading,
                    onProcesar: _procesarCotizacion,
                    esCotizacion: true,
                    carrito: formState.carrito,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanelConfig(
    CotizacionFormState state,
    CotizacionFormNotifier notifier,
    dynamic clienteState,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                'CONFIGURACIÓN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // CLIENTE
          Text(
            'CLIENTE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final cliente = await showDialog<Cliente>(
                context: context,
                builder: (ctx) =>
                    BuscadorClienteDialog(clientes: clienteState.clientes),
              );
              if (cliente != null) notifier.seleccionarCliente(cliente);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.clienteSeleccionado == null
                      ? Colors.grey.shade300
                      : AppColors.primary.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  if (state.clienteSeleccionado != null)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: state.clienteSeleccionado == null
                          ? Colors.grey.shade100
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      state.clienteSeleccionado == null
                          ? Icons.person_add_alt_1_outlined
                          : Icons.person,
                      color: state.clienteSeleccionado == null
                          ? Colors.grey.shade500
                          : AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.clienteSeleccionado?.nombre ??
                              'Seleccionar Cliente',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: state.clienteSeleccionado == null
                                ? Colors.grey.shade600
                                : AppColors.secondary,
                          ),
                        ),
                        if (state.clienteSeleccionado != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            state.clienteSeleccionado!.rncCedula ??
                                'Sin identificación',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // DÍAS VALIDEZ
          Text(
            'DÍAS DE VALIDEZ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              initialValue: state.diasValidez.toString(),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Ej. 15',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) =>
                  notifier.cambiarDiasValidez(int.tryParse(v) ?? 0),
            ),
          ),

          const SizedBox(height: 24),

          // NOTAS
          Text(
            'NOTAS / OBSERVACIONES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              initialValue: state.nota,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Añadir detalles adicionales de la cotización...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: notifier.cambiarNota,
            ),
          ),
        ],
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
      final name = TextNormalizer.normalizar(p.nombre?.toLowerCase() ?? "");

      return name.contains(
        TextNormalizer.normalizar(_searchQuery.toLowerCase()),
      );
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 13),
                      icon: Icon(Icons.search, color: Colors.grey, size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 140,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
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
            itbisPorcentaje: prod.impuesto?.tasa ?? 0,
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
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
                    top: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 32,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prod.nombre ?? 'Sin nombre',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            FormatterNumber.formatCurrency(prod.precioVenta ?? 0),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
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
          Icon(Icons.search_off_rounded, size: 32, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Text(
            'No se encontraron productos',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
