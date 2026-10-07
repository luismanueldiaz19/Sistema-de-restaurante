import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/nueva_compra_form_provider.dart';
import '../../../modulo_producto/providers/producto_provider.dart';
import '../../../modulo_producto/models/producto.dart';
import '../../../widgets/custom_text_field.dart';

class CompraDetalleDataGrid extends ConsumerStatefulWidget {
  const CompraDetalleDataGrid({super.key});

  @override
  ConsumerState<CompraDetalleDataGrid> createState() =>
      _CompraDetalleDataGridState();
}

class _CompraDetalleDataGridState extends ConsumerState<CompraDetalleDataGrid> {
  final TextEditingController _searchController = TextEditingController();

  void _agregarProducto(Producto producto) {
    double factor = producto.factorCompraPorDefecto ?? 1.0;
    double impuestoTasa = producto.impuesto?.tasa ?? 0.0;

    double precioPorPresentacion = 0.0;

    if ((producto.precioCompra ?? 0) > 0) {
      // El precioCompra ingresado en el formulario es el precio FINAL de la presentación con ITBIS
      precioPorPresentacion = producto.precioCompra!;
    } else {
      // Fallback: calcular basado en costo unitario sin ITBIS
      double costoBaseSinItbis = producto.costo ?? 0.0;
      double precioConItbis = costoBaseSinItbis * (1 + (impuestoTasa / 100));
      precioPorPresentacion = double.parse(
        (precioConItbis * factor).toStringAsFixed(2),
      );
    }

    // Extraer el ITBIS de ese precio final
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
    _searchController.clear();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(nuevaCompraFormProvider);
    final productos = ref.watch(productoProvider).productos;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Búsqueda tipo Autocomplete
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Autocomplete<Producto>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Producto>.empty();
                }
                return productos.where((Producto p) {
                  return (p.nombre ?? '').toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ) ||
                      (p.codigo ?? '').contains(textEditingValue.text);
                });
              },
              displayStringForOption: (Producto option) => option.nombre ?? '',
              onSelected: (Producto selection) {
                _agregarProducto(selection);
              },
              fieldViewBuilder:
                  (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Buscar producto por nombre o código...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (String value) {
                        onFieldSubmitted();
                      },
                    );
                  },
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Tabla de detalles
          if (formState.detalles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Busque y agregue productos a la factura',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else ...[
            // HEADERS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 40), // Spacing for delete icon
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'Producto / Ítem',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Presentación',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Factor',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Cant',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Precio de Compra',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'ITBIS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Subtotal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: formState.detalles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = formState.detalles[index];
                return _LineaCompraItem(
                  item: item,
                  index: index,
                  onUpdate: (updatedItem) {
                    ref
                        .read(nuevaCompraFormProvider.notifier)
                        .updateDetalle(index, updatedItem);
                  },
                  onDelete: () {
                    ref
                        .read(nuevaCompraFormProvider.notifier)
                        .removeDetalle(index);
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _LineaCompraItem extends StatefulWidget {
  final NuevaCompraDetalleItem item;
  final int index;
  final Function(NuevaCompraDetalleItem) onUpdate;
  final VoidCallback onDelete;

  const _LineaCompraItem({
    required this.item,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_LineaCompraItem> createState() => _LineaCompraItemState();
}

class _LineaCompraItemState extends State<_LineaCompraItem> {
  late TextEditingController _presentacionCtrl;
  late TextEditingController _factorCtrl;
  late TextEditingController _cantidadCtrl;
  late TextEditingController _costoCtrl;
  late TextEditingController _impuestoCtrl;

  @override
  void initState() {
    super.initState();
    _presentacionCtrl = TextEditingController(text: widget.item.presentacion);
    _factorCtrl = TextEditingController(
      text: widget.item.factorConversion.toString(),
    );
    _cantidadCtrl = TextEditingController(
      text: widget.item.cantidad.toString(),
    );
    _costoCtrl = TextEditingController(
      text: widget.item.costoUnitario.toString(),
    );
    _impuestoCtrl = TextEditingController(
      text: widget.item.impuestoMonto.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _LineaCompraItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item != oldWidget.item) {
      if (_presentacionCtrl.text != widget.item.presentacion) {
        _presentacionCtrl.text = widget.item.presentacion;
      }
      if (double.tryParse(_factorCtrl.text) != widget.item.factorConversion) {
        _factorCtrl.text = widget.item.factorConversion.toString();
      }
      if (double.tryParse(_cantidadCtrl.text) != widget.item.cantidad) {
        _cantidadCtrl.text = widget.item.cantidad.toString();
      }
      if (double.tryParse(_costoCtrl.text) != widget.item.costoUnitario) {
        _costoCtrl.text = widget.item.costoUnitario.toString();
      }
      if (double.tryParse(_impuestoCtrl.text) != widget.item.impuestoMonto) {
        _impuestoCtrl.text = widget.item.impuestoMonto.toString();
      }
    }
  }

  void _onCostoOCantidadChanged() {
    double cantidad = double.tryParse(_cantidadCtrl.text) ?? 0.0;
    double precioConItbis = double.tryParse(_costoCtrl.text) ?? 0.0;
    double impuestoTasa = widget.item.impuestoTasa;

    // Extraer el ITBIS del precio total
    double totalLinea = cantidad * precioConItbis;
    double nuevoImpuesto =
        totalLinea - (totalLinea / (1 + (impuestoTasa / 100)));
    _impuestoCtrl.text = nuevoImpuesto.toStringAsFixed(2);
    _notificarCambio();
  }

  void _notificarCambio() {
    final newItem = NuevaCompraDetalleItem(
      productoId: widget.item.productoId,
      productoNombre: widget.item.productoNombre,
      cuentaContableId: widget.item.cuentaContableId,
      descripcionGasto: widget.item.descripcionGasto,
      presentacion: _presentacionCtrl.text,
      factorConversion: double.tryParse(_factorCtrl.text) ?? 1.0,
      cantidad: double.tryParse(_cantidadCtrl.text) ?? 0.0,
      costoUnitario: double.tryParse(_costoCtrl.text) ?? 0.0,
      impuestoTasa: widget.item.impuestoTasa,
      impuestoMonto: double.tryParse(_impuestoCtrl.text) ?? 0.0,
    );
    widget.onUpdate(newItem);
  }

  @override
  void dispose() {
    _presentacionCtrl.dispose();
    _factorCtrl.dispose();
    _cantidadCtrl.dispose();
    _costoCtrl.dispose();
    _impuestoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Delete
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade600,
                size: 20,
              ),
              onPressed: widget.onDelete,
            ),
          ),
          const SizedBox(width: 8),
          // Nombre + Info de equivalencia
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.descripcionGasto ??
                      widget.item.productoNombre ??
                      'Item',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Equivale a: ${(widget.item.cantidad * widget.item.factorConversion).toStringAsFixed(2)} unid. (Costo: \$${(widget.item.costoUnitario / (widget.item.factorConversion > 0 ? widget.item.factorConversion : 1)).toStringAsFixed(2)}/u)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Presentación
          Expanded(
            flex: 2,
            child: CustomTextField(
              label: '',
              hintText: 'Presentación',
              controller: _presentacionCtrl,
              onChanged: (_) => _notificarCambio(),
            ),
          ),
          const SizedBox(width: 8),
          // Factor
          Expanded(
            flex: 1,
            child: CustomTextField(
              label: '',
              hintText: 'Factor',
              controller: _factorCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => _notificarCambio(),
            ),
          ),
          const SizedBox(width: 8),
          // Cantidad
          Expanded(
            flex: 1,
            child: CustomTextField(
              label: '',
              hintText: 'Cant',
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => _onCostoOCantidadChanged(),
            ),
          ),
          const SizedBox(width: 8),
          // Costo
          Expanded(
            flex: 2,
            child: CustomTextField(
              label: '',
              hintText: '\$ 0.00',
              controller: _costoCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => _onCostoOCantidadChanged(),
            ),
          ),
          const SizedBox(width: 8),
          // ITBIS
          Expanded(
            flex: 1,
            child: CustomTextField(
              label: '',
              hintText: 'ITBIS',
              controller: _impuestoCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => _notificarCambio(),
            ),
          ),
          const SizedBox(width: 8),
          // Total (Readonly)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(color: Colors.transparent),
                child: Text(
                  '\$${widget.item.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
