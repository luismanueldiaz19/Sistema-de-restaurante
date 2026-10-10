import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../palletes/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/percentage_slider.dart';
import '../../models/cxp.dart';
import '../../providers/cxp_provider.dart';
import '../../../utils/helpers.dart';
import '../../../facturacion/providers/metodo_pago_provider.dart';
import 'pagos_compra_dialog.dart';

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
  int? _metodoId;
  final int _cuentaOrigenId = 1;
  bool _isSubmitting = false;

  @override
  void didUpdateWidget(covariant CxpDetalleYPagoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cxp != oldWidget.cxp && widget.cxp != null) {
      _montoCtrl.text = widget.cxp!.balancePendiente.toStringAsFixed(2);
      _refCtrl.clear();
      _metodoId = null;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.cxp != null) {
      _montoCtrl.text = widget.cxp!.balancePendiente.toStringAsFixed(2);
    }
    Future.microtask(() => ref.read(metodoPagoProvider).fetchMetodosActivos());
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
              color: Colors.black.withValues(alpha: 0.05),
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
    final metodoState = ref.watch(metodoPagoProvider);
    final metodos = metodoState.metodos;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // CABECERA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
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
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cxp.proveedor?.nombre ?? 'Proveedor Desconocido',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Factura Nº ${compra?.numeroFacturaProveedor ?? "N/A"}',
                        style: TextStyle(
                          fontSize: 11,
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
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fecha: ${compra?.fechaCompra.toLocal().toString().split(' ')[0] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'NCF: ${compra?.ncf ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (cxp.fechaVencimiento.isBefore(DateTime.now())) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Factura vencida hace ${DateTime.now().difference(cxp.fechaVencimiento).inDays} días',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 16),
                const Text(
                  'PRODUCTOS ADQUIRIDOS:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
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
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${d.cantidad} x ${FormatterNumber.formatCurrency(d.costoUnitario)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              FormatterNumber.formatCurrency(d.total),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    Text(
                      FormatterNumber.formatCurrency(compra?.subtotal ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Impuestos:',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    Text(
                      FormatterNumber.formatCurrency(compra?.impuestos ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL FACTURA:',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      FormatterNumber.formatCurrency(compra?.total ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
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
            padding: const EdgeInsets.all(16),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Registrar Pago',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.secondary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => PagosCompraDialog(
                            compraId: cxp.compraId,
                            totalCompra: cxp.montoOriginal,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.history,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Historial de Pagos',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'BALANCE PENDIENTE',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        FormatterNumber.formatCurrency(cxp.balancePendiente),
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _montoCtrl,
                        label: 'Monto',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        prefixIcon: Icons.attach_money,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Método',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          metodoState.isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                              : DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: AppColors.azulOscuro,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    isDense: true,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                  initialValue:
                                      metodos.any((m) => m.id == _metodoId)
                                      ? _metodoId
                                      : null,
                                  hint: const Text('Seleccionar'),
                                  items: metodos.map((metodo) {
                                    return DropdownMenuItem<int>(
                                      value: metodo.id,
                                      child: Text(metodo.nombre),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _metodoId = val),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // SLIDER DE PORCENTAJE
                PercentageSlider(
                  totalValue: cxp.balancePendiente,
                  amountController: _montoCtrl,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _refCtrl,
                  label: 'Referencia (Opcional)',
                  prefixIcon: Icons.receipt_long,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      _isSubmitting ? 'PROCESANDO...' : 'CONFIRMAR PAGO',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final monto = double.tryParse(_montoCtrl.text) ?? 0;
                            if (monto <= 0 || monto > cxp.balancePendiente) {
                              showToast(
                                context,
                                'Monto inválido',
                                bgColor: Colors.red,
                              );
                              return;
                            }

                            if (_metodoId == null) {
                              showToast(
                                context,
                                'Selecciona un método de pago',
                                bgColor: Colors.red,
                              );
                              return;
                            }

                            setState(() {
                              _isSubmitting = true;
                            });

                            try {
                              final refText = _refCtrl.text.trim().isEmpty
                                  ? 'Pago Fac. ${compra?.numeroFacturaProveedor ?? ''}'
                                  : _refCtrl.text.trim();

                              final data = {
                                'monto_pagado': monto,
                                'fecha_pago': DateTime.now()
                                    .toIso8601String()
                                    .split('T')[0],
                                'metodo_pago_id': _metodoId,
                                'referencia': refText,
                                'cuenta_origen_id': _cuentaOrigenId,
                                'compra_id': cxp.compraId,
                              };

                              final errorMsg = await ref
                                  .read(cxpProvider.notifier)
                                  .registrarPago(cxp.id, data);

                              if (errorMsg == null && context.mounted) {
                                showToast(
                                  context,
                                  'Pago registrado con éxito',
                                  bgColor: Colors.green,
                                );
                                widget.onPagoCompletado();
                              } else if (context.mounted) {
                                // Limpiamos un poco el mensaje si viene en JSON
                                String msj =
                                    errorMsg ?? 'Error al procesar pago';
                                if (msj.contains('message":"')) {
                                  try {
                                    final match = RegExp(
                                      r'"message":"([^"]+)"',
                                    ).firstMatch(msj);
                                    if (match != null) {
                                      msj = match.group(1)!;
                                    }
                                  } catch (_) {}
                                }
                                showToast(context, msj, bgColor: Colors.red);
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isSubmitting = false;
                                });
                              }
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
