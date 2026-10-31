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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          // Header del catálogo y buscador compacto
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lista de Productos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    '${filteredProducts.length} productos disponibles',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 250,
                height: 36,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 18,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            padding: EdgeInsets.zero,
                            splashRadius: 14,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 18,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: filteredProducts.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 160,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.88,
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
    final bool controlaStock = prod.manejaInventario ?? false;
    final double stock = prod.stockActual ?? 0;
    final double stockMin = prod.stockMinimo ?? 0;

    Color stockColor = AppColors.success;
    if (controlaStock) {
      if (stock <= 0) {
        stockColor = Colors.redAccent;
      } else if (stock <= stockMin) {
        stockColor = Colors.orange.shade700;
      }
    }

    final double precioCosto =
        (prod.precioCompra != null && prod.precioCompra! > 0)
        ? prod.precioCompra!
        : (prod.costo ?? 0.0);

    return Tooltip(
      message: prod.nombre ?? '',
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => _agregarProductoAlCarrito(prod),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
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
                      size: 28,
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
                    SizedBox(
                      height: 28,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          prod.nombre ?? 'Sin nombre',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            height: 1.18,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              FormatterNumber.formatCurrency(precioCosto),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                        if (controlaStock) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message:
                                'Stock actual: ${FormatterNumber.formatNumber(stock)}',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: stockColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'S: ${FormatterNumber.formatNumber(stock)}',
                                style: TextStyle(
                                  color: stockColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No se encontraron productos para "$_searchQuery"'
                : 'No hay productos disponibles',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
