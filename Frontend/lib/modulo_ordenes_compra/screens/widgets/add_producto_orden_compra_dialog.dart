import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../utils/helpers.dart';
import '../../../modulo_producto/models/producto.dart';
import '../../../facturacion/models/factura_item.dart';

class AddProductoOrdenCompraDialog extends StatefulWidget {
  final Producto producto;
  final Function(FacturaItem detalle) onAdd;

  const AddProductoOrdenCompraDialog({
    super.key,
    required this.producto,
    required this.onAdd,
  });

  @override
  State<AddProductoOrdenCompraDialog> createState() =>
      _AddProductoOrdenCompraDialogState();
}

class _AddProductoOrdenCompraDialogState
    extends State<AddProductoOrdenCompraDialog> {
  late TextEditingController cantCtrl;
  late TextEditingController costoCtrl;
  late TextEditingController totalCtrl;
  late TextEditingController impCtrl;
  bool isExento = false;

  @override
  void initState() {
    super.initState();
    cantCtrl = TextEditingController(text: '1');
    costoCtrl = TextEditingController(
      text: (widget.producto.ultimoCosto ?? 0).toString(),
    );
    totalCtrl = TextEditingController(
      text: (widget.producto.ultimoCosto ?? 0).toString(),
    );

    isExento = _verificarSiEsExento();

    final taxRate = isExento
        ? 0.0
        : (widget.producto.impuesto?.tasa != null &&
                  widget.producto.impuesto!.tasa > 0
              ? (widget.producto.impuesto!.tasa / 100)
              : 0.18);
    impCtrl = TextEditingController(
      text: ((widget.producto.ultimoCosto ?? 0) * taxRate).toStringAsFixed(2),
    );
  }

  bool _verificarSiEsExento() {
    if (widget.producto.impuesto != null) {
      return widget.producto.impuesto!.tasa == 0.0;
    }
    return false; // Default: si no hay impuesto definido, asumimos que no es exento (paga 18% por defecto) o puedes ajustarlo.
  }

  @override
  void dispose() {
    cantCtrl.dispose();
    costoCtrl.dispose();
    totalCtrl.dispose();
    impCtrl.dispose();
    super.dispose();
  }

  void _updateCalc({bool fromTotal = false}) {
    final cant = double.tryParse(cantCtrl.text) ?? 0.0;
    final taxRate = isExento
        ? 0.0
        : (widget.producto.impuesto?.tasa != null &&
                  widget.producto.impuesto!.tasa > 0
              ? (widget.producto.impuesto!.tasa / 100)
              : 0.18);
    final divBase = 1 + taxRate;

    if (fromTotal) {
      final totalLinea = double.tryParse(totalCtrl.text) ?? 0.0;
      final costoConItbis = cant > 0 ? totalLinea / cant : 0.0;
      costoCtrl.text = costoConItbis.toStringAsFixed(2);

      if (isExento) {
        impCtrl.text = '0.00';
      } else {
        final base = totalLinea / divBase;
        impCtrl.text = (totalLinea - base).toStringAsFixed(2);
      }
    } else {
      final costoConItbis = double.tryParse(costoCtrl.text) ?? 0.0;
      final totalLinea = cant * costoConItbis;

      totalCtrl.text = totalLinea.toStringAsFixed(2);

      if (isExento) {
        impCtrl.text = '0.00';
      } else {
        final base = totalLinea / divBase;
        impCtrl.text = (totalLinea - base).toStringAsFixed(2);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cant = double.tryParse(cantCtrl.text) ?? 0.0;
    final costoConItbis = double.tryParse(costoCtrl.text) ?? 0.0;
    final total = cant * costoConItbis;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Ordenar: ${widget.producto.nombre}',
        style: const TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Costo Anterior (Ref): ${formatCurrency(widget.producto.ultimoCosto ?? 0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: cantCtrl,
                    label: 'Cantidad a Comprar',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (v) =>
                        setState(() => _updateCalc(fromTotal: false)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: costoCtrl,
                    label: 'Costo Unitario (Auto)',
                    enabled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: totalCtrl,
                    label: 'Total Pagado',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (v) =>
                        setState(() => _updateCalc(fromTotal: true)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: impCtrl,
                    label: 'Monto Impuesto',
                    enabled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total de esta línea:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatCurrency(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (cantCtrl.text.isEmpty || costoCtrl.text.isEmpty) return;

            final cantIngresada = double.parse(cantCtrl.text);
            final costoIngresado = double.parse(
              costoCtrl.text,
            ); // Esto ya incluye ITBIS en el total calculado
            final taxRate =
                widget.producto.impuesto?.tasa != null &&
                    widget.producto.impuesto!.tasa > 0
                ? widget.producto.impuesto!.tasa
                : 18.0;
            final itbisPercent = isExento ? 0.0 : taxRate;

            widget.onAdd(
              FacturaItem(
                id: widget.producto.id.toString(),
                descripcion: widget.producto.nombre ?? 'Sin nombre',
                precio: costoIngresado, // FacturaItem usa precio con ITBIS
                cantidad: cantIngresada,
                itbisPorcentaje: itbisPercent,
              ),
            );

            Navigator.pop(context);
          },
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: const Text('Agregar a la Orden'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
