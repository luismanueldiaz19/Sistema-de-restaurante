import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../utils/helpers.dart';
import '../../../modulo_producto/models/producto.dart';
import '../../../modulo_producto/providers/producto_provider.dart';
import '../../providers/nueva_compra_form_provider.dart';

class CompraCatalogoProductos extends ConsumerStatefulWidget {
  const CompraCatalogoProductos({super.key});

  @override
  ConsumerState<CompraCatalogoProductos> createState() =>
      _CompraCatalogoProductosState();
}

class _CompraCatalogoProductosState
    extends ConsumerState<CompraCatalogoProductos> {
  String _searchQuery = "";

  void _agregarProductoAlCarrito(Producto producto) {
    double factor = producto.factorCompraPorDefecto ?? 1.0;
    double impuestoTasa = producto.impuesto?.tasa ?? 0.0;

    double precioPorPresentacion = 0.0;

    if ((producto.precioCompra ?? 0) > 0) {
      precioPorPresentacion = producto.precioCompra!;
    } else {
      double costoBaseSinItbis = producto.costo ?? 0.0;
      double precioConItbis = costoBaseSinItbis * (1 + (impuestoTasa / 100));
      precioPorPresentacion = double.parse(
        (precioConItbis * factor).toStringAsFixed(2),
      );
    }

    double impuestoCalculado =
        precioPorPresentacion -
        (precioPorPresentacion / (1 + (impuestoTasa / 100)));
    double impuestoMontoPorPresentacion = double.parse(
      impuestoCalculado.toStringAsFixed(2),
    );

    final newItem = NuevaCompraDetalleItem(
      productoId: producto.id,
      productoNombre: producto.nombre,
      presentacion: producto.presentacionCompraPorDefecto?.isNotEmpty == true
          ? producto.presentacionCompraPorDefecto!
          : (producto.unidadMedida?.nombre ?? 'Unidad'),
      factorConversion: factor,
      cantidad: 1,
      costoUnitario: precioPorPresentacion,
      impuestoTasa: impuestoTasa,
      impuestoMonto: impuestoMontoPorPresentacion,
    );
    ref.read(nuevaCompraFormProvider.notifier).addDetalle(newItem);
  }

  @override
  Widget build(BuildContext context) {
    final prodState = ref.watch(productosCompraProvider);

    if (prodState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final filteredProducts = prodState.productos.where((p) {
      if (p.tipoProducto == 'COMBO') return false;
      final name = p.nombre?.toLowerCase() ?? "";
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header del catálogo y buscador
          Row(
            children: [
              const Text(
                'Catálogo de Productos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: 300,
                height: 40,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredProducts.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 160,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final prod = filteredProducts[index];
                      return _buildProductCard(prod);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Producto prod) {
    return InkWell(
      onTap: () => _agregarProductoAlCarrito(prod),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 36,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prod.nombre ?? 'Sin nombre',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ref: ${FormatterNumber.formatCurrency(prod.costo ?? 0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
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
}
