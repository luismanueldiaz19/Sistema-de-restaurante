import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/nueva_compra_form_provider.dart';
import '../../../modulo_producto/providers/producto_provider.dart';
import '../../../modulo_producto/models/producto.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../utils/helpers.dart';
import 'compra_catalogo_productos.dart';

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
    final productos = ref.watch(productosCompraProvider).productos;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            padding: const EdgeInsets.all(12.0),
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
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Buscar producto por nombre o código...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12.5,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.list_alt, size: 20),
                          color: Theme.of(context).primaryColor,
                          tooltip: 'Abrir catálogo de productos',
                          splashRadius: 18,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const Dialog(
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                                child: SizedBox(
                                  width: 640,
                                  height: 480,
                                  child: CompraCatalogoProductos(),
                                ),
                              ),
                            );
                          },
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
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (String value) {
                        onFieldSubmitted();
                      },
                    );
                  },
            ),
          ),

          // Tabla Empresarial de Detalles
          if (formState.detalles.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const minTableWidth = 920.0;
                  final tableWidth = constraints.maxWidth > minTableWidth
                      ? constraints.maxWidth
                      : minTableWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        children: [
                          // Cabecera de la tabla
                          _buildTableHeader(),

                          // Filas de la tabla
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: formState.detalles.length,
                              itemBuilder: (context, index) {
                                final item = formState.detalles[index];
                                return _LineaCompraItem(
                                  key: ValueKey(item.productoId ?? index),
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
                          ),

                          // Pie de la tabla
                          _buildTableFooter(formState.detalles),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '#',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 7,
            child: Text(
              'PRODUCTO / ÍTEM',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF4B5563),
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              'EMPAQUE',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF4B5563),
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              'UNID. X EMP.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF4B5563),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              'CANT.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF4B5563),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              'PRECIO COMPRA',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF4B5563),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              'ITBIS',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF4B5563),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              'SUBTOTAL',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF4B5563),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Center(
              child: Icon(
                Icons.settings_outlined,
                size: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableFooter(List<NuevaCompraDetalleItem> detalles) {
    final double totalCantidad =
        detalles.fold(0.0, (acc, item) => acc + item.cantidad);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${detalles.length} ${detalles.length == 1 ? 'ítem en lista' : 'ítems en lista'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Total cantidad: ${FormatterNumber.formatNumber(totalCantidad)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 42,
              color: Color(0xFFD1D5DB),
            ),
            SizedBox(height: 8),
            Text(
              'No hay productos en esta compra',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Usa el buscador superior o abre el catálogo para agregar artículos a la factura.',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 11,
              ),
            ),
          ],
        ),
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
    super.key,
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
  bool _isHovered = false;

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
    final rowColor = _isHovered
        ? AppColors.primary.withValues(alpha: 0.04)
        : (widget.index.isEven ? Colors.white : const Color(0xFFFAFBFC));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: rowColor,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // # Índice
            SizedBox(
              width: 32,
              child: Center(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Producto / Ítem
            Expanded(
              flex: 7,
              child: Text(
                widget.item.descripcionGasto ??
                    widget.item.productoNombre ??
                    'Item',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.secondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Empaque
            Expanded(
              flex: 3,
              child: _TableInputCell(
                controller: _presentacionCtrl,
                hintText: 'Empaque',
                onChanged: (_) => _notificarCambio(),
              ),
            ),
            const SizedBox(width: 8),

            // Unid. x Empaque
            Expanded(
              flex: 2,
              child: _TableInputCell(
                controller: _factorCtrl,
                hintText: 'Unidades',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (_) => _notificarCambio(),
              ),
            ),
            const SizedBox(width: 8),

            // Cantidad
            Expanded(
              flex: 2,
              child: _TableInputCell(
                controller: _cantidadCtrl,
                hintText: 'Cant',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (_) => _onCostoOCantidadChanged(),
              ),
            ),
            const SizedBox(width: 8),

            // Precio Compra (Costo)
            Expanded(
              flex: 3,
              child: _TableInputCell(
                controller: _costoCtrl,
                hintText: '0.00',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                prefixText: '\$ ',
                onChanged: (_) => _onCostoOCantidadChanged(),
              ),
            ),
            const SizedBox(width: 8),

            // ITBIS
            Expanded(
              flex: 2,
              child: _TableInputCell(
                controller: _impuestoCtrl,
                hintText: '0.00',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                prefixText: '\$ ',
                onChanged: (_) => _notificarCambio(),
              ),
            ),
            const SizedBox(width: 8),

            // Subtotal
            Expanded(
              flex: 3,
              child: Text(
                FormatterNumber.formatCurrency(widget.item.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),

            // Acción Eliminar
            SizedBox(
              width: 36,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                  ),
                  color: Colors.grey.shade400,
                  hoverColor: Colors.red.shade50,
                  tooltip: 'Eliminar fila',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  splashRadius: 14,
                  onPressed: widget.onDelete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableInputCell extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final String? prefixText;

  const _TableInputCell({
    required this.controller,
    this.hintText = '',
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: textAlign,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          prefixText: prefixText,
          prefixStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
          hintStyle: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 7,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
