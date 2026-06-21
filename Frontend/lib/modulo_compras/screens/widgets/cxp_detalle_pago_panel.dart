import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../palletes/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import '../../models/cxp.dart';
import '../../providers/cxp_provider.dart';
import '../../../utils/helpers.dart';

class CxpDetalleYPagoPanel extends ConsumerStatefulWidget {
  final CuentaPorPagar? cxp;
  final VoidCallback onPagoCompletado;

  const CxpDetalleYPagoPanel({
    super.key,
    required this.cxp,
    required this.onPagoCompletado,
  });

  @override
  ConsumerState<CxpDetalleYPagoPanel> createState() =>
      _CxpDetalleYPagoPanelState();
}

class _CxpDetalleYPagoPanelState extends ConsumerState<CxpDetalleYPagoPanel> {
  final _montoCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String _metodo = 'EFECTIVO';
  final int _cuentaOrigenId = 1;

  @override
  void didUpdateWidget(covariant CxpDetalleYPagoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cxp != oldWidget.cxp && widget.cxp != null) {
      _montoCtrl.text = widget.cxp!.balancePendiente.toStringAsFixed(2);
      _refCtrl.clear();
      _metodo = 'EFECTIVO';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.cxp != null) {
      _montoCtrl.text = widget.cxp!.balancePendiente.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cxp == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Selecciona una cuenta por pagar',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final cxp = widget.cxp!;
    final compra = cxp.compra;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // CABECERA
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cxp.proveedor?.nombre ?? 'Proveedor Desconocido',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Factura Nº ${compra?.numeroFacturaProveedor ?? "N/A"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // DETALLES DE LA FACTURA
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fecha: ${compra?.fechaCompra.toLocal().toString().split(' ')[0] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'NCF: ${compra?.ncf ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text(
                  'PRODUCTOS ADQUIRIDOS:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                if (compra?.detalles == null || compra!.detalles.isEmpty)
                  const Text('No hay detalles para mostrar.')
                else
                  ...compra.detalles.map<Widget>((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.producto?.nombre ??
                                      d.descripcion ??
                                      'Desconocido',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${d.cantidad} x ${formatCurrency(d.costoUnitario)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              formatCurrency(d.total),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      formatCurrency(compra?.subtotal ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Impuestos:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      formatCurrency(compra?.impuestos ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL FACTURA:',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      formatCurrency(compra?.total ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // FORMULARIO DE PAGO
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrar Pago',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'BALANCE PENDIENTE',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatCurrency(cxp.balancePendiente),
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _montoCtrl,
                        label: 'Monto',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.attach_money,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Método',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        value: _metodo,
                        items: const [
                          DropdownMenuItem(
                            value: 'EFECTIVO',
                            child: Text('Efectivo'),
                          ),
                          DropdownMenuItem(
                            value: 'TRANSFERENCIA',
                            child: Text('Transferencia'),
                          ),
                          DropdownMenuItem(
                            value: 'CHEQUE',
                            child: Text('Cheque'),
                          ),
                        ],
                        onChanged: (val) => setState(() => _metodo = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _refCtrl,
                  label: 'Referencia (Opcional)',
                  prefixIcon: Icons.receipt_long,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text(
                      'CONFIRMAR PAGO',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final monto = double.tryParse(_montoCtrl.text) ?? 0;
                      if (monto <= 0 || monto > cxp.balancePendiente) {
                        showToast(
                          context,
                          'Monto inválido',
                          bgColor: Colors.red,
                        );
                        return;
                      }

                      final data = {
                        'monto_pagado': monto,
                        'fecha_pago': DateTime.now().toIso8601String().split(
                          'T',
                        )[0],
                        'metodo_pago': _metodo,
                        'referencia': _refCtrl.text,
                        'cuenta_origen_id': _cuentaOrigenId,
                      };

                      final success = await ref
                          .read(cxpProvider.notifier)
                          .registrarPago(cxp.id, data);
                      if (success && context.mounted) {
                        showToast(
                          context,
                          'Pago registrado con éxito',
                          bgColor: Colors.green,
                        );
                        widget.onPagoCompletado();
                      } else if (context.mounted) {
                        showToast(
                          context,
                          'Error al procesar pago',
                          bgColor: Colors.red,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
