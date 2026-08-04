import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../palletes/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import '../../models/cxc.dart';
import '../../providers/cxc_provider.dart';
import '../../../utils/helpers.dart';

class CxcDetalleCobroPanel extends ConsumerStatefulWidget {
  final CuentaPorCobrar? cxc;
  final VoidCallback onCobroCompletado;

  const CxcDetalleCobroPanel({
    super.key,
    required this.cxc,
    required this.onCobroCompletado,
  });

  @override
  ConsumerState<CxcDetalleCobroPanel> createState() =>
      _CxcDetalleCobroPanelState();
}

class _CxcDetalleCobroPanelState extends ConsumerState<CxcDetalleCobroPanel> {
  final _montoCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String _metodo = 'EFECTIVO';
  final int _cuentaDestinoId = 1; // Assuming account 1 is Caja General / Efectivo

  @override
  void didUpdateWidget(covariant CxcDetalleCobroPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cxc != oldWidget.cxc && widget.cxc != null) {
      _montoCtrl.text = widget.cxc!.balancePendiente.toStringAsFixed(2);
      _refCtrl.clear();
      _metodo = 'EFECTIVO';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.cxc != null) {
      _montoCtrl.text = widget.cxc!.balancePendiente.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cxc == null) {
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
              Icon(Icons.request_quote, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Selecciona una cuenta por cobrar',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final cxc = widget.cxc!;
    final factura = cxc.factura;

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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cxc.cliente?['nombre'] ?? 'Cliente Desconocido',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Factura NCF ${factura?['ncf'] ?? "N/A"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cxc.estado == 'PENDIENTE'
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cxc.estado,
                    style: TextStyle(
                      color: cxc.estado == 'PENDIENTE'
                          ? Colors.red
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              ],
            ),
          ),

          // DETALLE PRODUCTOS (Scrollable)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Detalle de la Venta',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                if (factura != null && factura['detalles'] != null)
                  ...List.generate(factura['detalles'].length, (index) {
                    final d = factura['detalles'][index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['producto']?['nombre'] ??
                                      d['descripcion'] ??
                                      'Desconocido',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${d['cantidad']} x ${formatCurrency(double.tryParse(d['precio_unitario'].toString()) ?? 0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatCurrency(double.tryParse(d['subtotal'].toString()) ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  const Text('No hay detalles disponibles'),

                const Divider(height: 32),

                // Resumen Totales
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      formatCurrency(double.tryParse(factura?['subtotal']?.toString() ?? '0') ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Impuestos:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      formatCurrency(double.tryParse(factura?['itbis_total']?.toString() ?? '0') ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      formatCurrency(double.tryParse(factura?['total']?.toString() ?? '0') ?? 0),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // FORMULARIO DE COBRO
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
                  'Registrar Cobro',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'BALANCE PENDIENTE',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatCurrency(cxc.balancePendiente),
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _montoCtrl,
                        label: 'Monto a Cobrar',
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Método',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        initialValue: _metodo,
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
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _refCtrl,
                  label: 'Referencia (Opcional)',
                  prefixIcon: Icons.receipt_long,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text(
                      'CONFIRMAR COBRO',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final monto = double.tryParse(_montoCtrl.text) ?? 0;
                      if (monto <= 0 || monto > cxc.balancePendiente) {
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
                        'cuenta_destino_id': _cuentaDestinoId,
                      };

                      final success = await ref
                          .read(cxcProvider.notifier)
                          .registrarPago(cxc.id, data);
                      if (success && context.mounted) {
                        showToast(
                          context,
                          'Cobro registrado con éxito',
                          bgColor: Colors.green,
                        );
                        widget.onCobroCompletado();
                      } else if (context.mounted) {
                        showToast(
                          context,
                          'Error al procesar cobro',
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
