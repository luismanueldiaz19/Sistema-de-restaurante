import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../utils/helpers.dart';
import '../../../modulo_producto/models/producto.dart';
import '../../providers/nueva_compra_form_provider.dart';

class AddProductoCompraDialog extends StatefulWidget {
  final Producto producto;
  final Function(NuevaCompraDetalleItem detalle) onAdd;

  const AddProductoCompraDialog({
    Key? key,
    required this.producto,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddProductoCompraDialog> createState() =>
      _AddProductoCompraDialogState();
}

class _AddProductoCompraDialogState extends State<AddProductoCompraDialog> {
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
    impCtrl = TextEditingController(
      text: ((widget.producto.ultimoCosto ?? 0) * 0.18).toStringAsFixed(2),
    );
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

    if (fromTotal) {
      final totalLinea = double.tryParse(totalCtrl.text) ?? 0.0;
      final costoConItbis = cant > 0 ? totalLinea / cant : 0.0;
      costoCtrl.text = costoConItbis.toStringAsFixed(2);

      if (isExento) {
        impCtrl.text = '0.00';
      } else {
        final base = totalLinea / 1.18;
        impCtrl.text = (totalLinea - base).toStringAsFixed(2);
      }
    } else {
      final costoConItbis = double.tryParse(costoCtrl.text) ?? 0.0;
      final totalLinea = cant * costoConItbis;

      totalCtrl.text = totalLinea.toStringAsFixed(2);

      if (isExento) {
        impCtrl.text = '0.00';
      } else {
        final base = totalLinea / 1.18;
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
        'Comprar: ${widget.producto.nombre}',
        style: const TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.bold,
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
            CustomTextField(
              controller: cantCtrl,
              label: 'Cantidad a Comprar',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (v) => setState(() => _updateCalc(fromTotal: false)),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: totalCtrl,
              label: 'Total Pagado por esta línea',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (v) => setState(() => _updateCalc(fromTotal: true)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '¿Producto Exento de ITBIS?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  Switch(
                    value: isExento,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        isExento = val;
                        _updateCalc();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: impCtrl,
              label: 'Monto Impuesto (Total)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: costoCtrl,
              label: 'Costo Unitario (Calculado automáticamente)',
              enabled: false,
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
            final costoIngresado = double.parse(costoCtrl.text);
            final impuestoManual = double.tryParse(impCtrl.text) ?? 0.0;

            double costoBaseReal = costoIngresado;
            if (cantIngresada > 0) {
              costoBaseReal =
                  (costoIngresado * cantIngresada - impuestoManual) /
                  cantIngresada;
            }

            widget.onAdd(NuevaCompraDetalleItem(
              productoId: widget.producto.id ?? 0,
              productoNombre: widget.producto.nombre ?? 'Desconocido',
              cantidad: cantIngresada,
              costoUnitario: costoBaseReal,
              impuestoMonto: impuestoManual,
            ));

            Navigator.pop(context);
          },
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: const Text('Agregar al Carrito'),
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
