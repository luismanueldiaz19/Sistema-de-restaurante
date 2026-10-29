import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../palletes/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import '../../models/cxp.dart';
import '../../providers/cxp_provider.dart';
import '../../../utils/helpers.dart';
import '../../../facturacion/models/metodo_pago.dart';
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
  MetodoPago? _metodoPagoSeleccionado;
  final int _cuentaOrigenId = 1;
  bool _isSubmitting = false;

  @override
  void didUpdateWidget(covariant CxpDetalleYPagoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cxp != oldWidget.cxp && widget.cxp != null) {
      _montoCtrl.text = widget.cxp!.balancePendiente.toStringAsFixed(2);
      _refCtrl.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.cxp != null) {
      _montoCtrl.text = widget.cxp!.balancePendiente.toStringAsFixed(2);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(metodoPagoProvider).fetchMetodosActivos().then((_) {
        if (!mounted) return;
        final prov = ref.read(metodoPagoProvider);
        if (prov.metodos.isNotEmpty && _metodoPagoSeleccionado == null) {
          setState(() {
            _metodoPagoSeleccionado = prov.metodos.first;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  void _asignarMontoRapido(double ratio) {
    if (widget.cxp == null) return;
    final total = widget.cxp!.balancePendiente;
    final monto = total * ratio;
    setState(() {
      _montoCtrl.text = monto > 0 ? monto.toStringAsFixed(2) : '';
    });
  }

  Future<void> _procesarPago() async {
    final cxp = widget.cxp;
    if (cxp == null) return;

    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    if (monto <= 0) {
      showToast(context, 'Ingrese un monto mayor a cero', bgColor: Colors.red);
      return;
    }
    if (monto > cxp.balancePendiente) {
      showToast(context, 'El monto no puede superar el balance pendiente', bgColor: Colors.red);
      return;
    }

    if (_metodoPagoSeleccionado == null) {
      showToast(context, 'Seleccione un método de pago', bgColor: Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final compra = cxp.compra;
      final refText = _refCtrl.text.trim().isEmpty
          ? 'Pago Fac. ${compra?.numeroFacturaProveedor ?? ''}'
          : _refCtrl.text.trim();

      final data = {
        'monto_pagado': monto,
        'fecha_pago': DateTime.now().toIso8601String().split('T')[0],
        'metodo_pago_id': _metodoPagoSeleccionado!.id,
        'referencia': refText,
        'cuenta_origen_id': _cuentaOrigenId,
        'compra_id': cxp.compraId,
      };

      final errorMsg = await ref.read(cxpProvider.notifier).registrarPago(cxp.id, data);

      if (errorMsg == null && mounted) {
        showToast(context, 'Pago a proveedor registrado con éxito', bgColor: const Color(0xFF059669));
        widget.onPagoCompletado();
      } else if (mounted) {
        String msj = errorMsg ?? 'Error al procesar pago';
        if (msj.contains('message":"')) {
          try {
            final match = RegExp(r'"message":"([^"]+)"').firstMatch(msj);
            if (match != null) {
              msj = match.group(1)!;
            }
          } catch (_) {}
        }
        showToast(context, msj, bgColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cxp == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF64748B),
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Detalle de la Cuenta por Pagar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona una factura de la lista para ver los productos adquiridos y registrar pagos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
              ),
            ],
          ),
        ),
      );
    }

    final cxp = widget.cxp!;
    final compra = cxp.compra;
    final now = DateTime.now();
    final isVencida = cxp.fechaVencimiento.isBefore(now);
    final estaPagada = cxp.balancePendiente <= 0;
    final totalPagadoPrevio = (cxp.montoOriginal - cxp.balancePendiente).clamp(0.0, double.infinity);

    final metodoState = ref.watch(metodoPagoProvider);
    final metodos = metodoState.metodos.where((m) => m.activo).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Cabecera Proveedor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_rounded,
                    color: Color(0xFFD97706),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cxp.proveedor?.nombre ?? 'Proveedor General',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Factura Nº ${compra?.numeroFacturaProveedor ?? "N/A"}${compra?.ncf != null && compra!.ncf!.isNotEmpty ? " • NCF: ${compra.ncf}" : ""}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón Pagos Previos
                SizedBox(
                  height: 28,
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => PagosCompraDialog(
                          compraId: cxp.compraId,
                          totalCompra: cxp.montoOriginal,
                        ),
                      );
                    },
                    icon: const Icon(Icons.history_rounded, size: 14),
                    label: const Text('Abonos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.azulOscuro,
                      backgroundColor: const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Badge Estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: estaPagada
                        ? const Color(0xFFECFDF5)
                        : (isVencida ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: estaPagada
                          ? const Color(0xFFA7F3D0)
                          : (isVencida ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A)),
                    ),
                  ),
                  child: Text(
                    estaPagada ? 'PAGADA' : (isVencida ? 'VENCIDA' : 'PENDIENTE'),
                    style: TextStyle(
                      color: estaPagada
                          ? const Color(0xFF059669)
                          : (isVencida ? const Color(0xFFDC2626) : const Color(0xFFB45309)),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Contenido Scrollable (Detalle de productos y Totales)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Fecha de emisión y vencimiento
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Emisión: ${compra?.fechaCompra.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.event_available_outlined, size: 11, color: isVencida && !estaPagada ? const Color(0xFFDC2626) : Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Límite: ${cxp.fechaVencimiento.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isVencida && !estaPagada ? const Color(0xFFDC2626) : Colors.grey.shade600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Mini tabla de productos
                  const Text(
                    'PRODUCTOS ADQUIRIDOS',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Encabezado de la tabla de productos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 5, child: Text('DESCRIPCIÓN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                        Expanded(flex: 2, child: Text('CANT.', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                        Expanded(flex: 3, child: Text('COSTO', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                        Expanded(flex: 3, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  if (compra?.detalles == null || compra!.detalles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'Sin detalles de productos registrados.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: compra.detalles.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, idx) {
                        final d = compra.detalles[idx];
                        final nombre = d.producto?.nombre ?? d.descripcion ?? 'Producto';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(
                                  nombre,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  d.cantidad.toStringAsFixed(d.cantidad % 1 == 0 ? 0 : 2),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  FormatterNumber.formatCurrency(d.costoUnitario),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  FormatterNumber.formatCurrency(d.total),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),

                  // Desglose de Totales
                  _buildTotalRow('Subtotal:', FormatterNumber.formatCurrency(compra?.subtotal ?? 0)),
                  const SizedBox(height: 3),
                  _buildTotalRow('Impuestos (ITBIS):', FormatterNumber.formatCurrency(compra?.impuestos ?? 0)),
                  if (totalPagadoPrevio > 0) ...[
                    const SizedBox(height: 3),
                    _buildTotalRow('Abonos Registrados:', '- ${FormatterNumber.formatCurrency(totalPagadoPrevio)}', color: const Color(0xFF059669)),
                  ],
                  const SizedBox(height: 6),
                  _buildTotalRow('TOTAL FACTURA:', FormatterNumber.formatCurrency(compra?.total ?? cxp.montoOriginal), isBold: true),
                ],
              ),
            ),
          ),

          // 3. Formulario de Pago
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Banner Balance Pendiente con Accesos Rápidos
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: estaPagada ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: estaPagada ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        estaPagada ? 'FACTURA SALDADA' : 'BALANCE PENDIENTE',
                        style: TextStyle(
                          color: estaPagada ? const Color(0xFF059669) : const Color(0xFFB45309),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        FormatterNumber.formatCurrency(cxp.balancePendiente),
                        style: TextStyle(
                          color: estaPagada ? const Color(0xFF059669) : const Color(0xFFB45309),
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),

                if (!estaPagada) ...[
                  const SizedBox(height: 8),

                  // Chips de Monto Rápido
                  Row(
                    children: [
                      const Text(
                        'Abono rápido:',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickAmountButton('100% Saldo Total', 1.0),
                      const SizedBox(width: 6),
                      _buildQuickAmountButton('50% Mitad', 0.5),
                      const SizedBox(width: 6),
                      _buildQuickAmountButton('Limpiar', 0.0),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Campos: Monto y Método
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Input Monto
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monto a Pagar',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 36,
                              child: TextField(
                                controller: _montoCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.attach_money, size: 16, color: Color(0xFF64748B)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                    borderSide: BorderSide(color: AppColors.azulOscuro, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Selector de Método
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Método de Pago',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 36,
                              child: DropdownButtonFormField<MetodoPago>(
                                isDense: true,
                                initialValue: metodos.contains(_metodoPagoSeleccionado)
                                    ? _metodoPagoSeleccionado
                                    : (metodos.isNotEmpty ? metodos.first : null),
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                    borderSide: BorderSide(color: AppColors.azulOscuro, width: 1.5),
                                  ),
                                ),
                                items: metodos.map((metodo) {
                                  IconData mIcon;
                                  Color mColor;
                                  switch (metodo.tipo.toLowerCase()) {
                                    case 'tarjeta':
                                      mIcon = Icons.credit_card_rounded;
                                      mColor = const Color(0xFF2563EB);
                                      break;
                                    case 'transferencia':
                                      mIcon = Icons.account_balance_rounded;
                                      mColor = const Color(0xFF7C3AED);
                                      break;
                                    case 'efectivo':
                                    default:
                                      mIcon = Icons.payments_rounded;
                                      mColor = const Color(0xFF059669);
                                      break;
                                  }

                                  return DropdownMenuItem<MetodoPago>(
                                    value: metodo,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(mIcon, size: 14, color: mColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          metodo.nombre,
                                          style: const TextStyle(fontSize: 11.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _metodoPagoSeleccionado = val),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Referencia
                  CustomTextField(
                    controller: _refCtrl,
                    label: 'Referencia / No. Comprobante (Opcional)',
                    hintText: 'Ej. Cheque #987, Transferencia #54321...',
                    prefixIcon: Icons.receipt_long_outlined,
                  ),

                  const SizedBox(height: 10),

                  // Botón Confirmar Pago
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _procesarPago,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text(
                        _isSubmitting ? 'Procesando Pago...' : 'CONFIRMAR PAGO',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(String label, double ratio) {
    return InkWell(
      onTap: () => _asignarMontoRapido(ratio),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            fontSize: isBold ? 11.5 : 11,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? (isBold ? const Color(0xFF0F172A) : const Color(0xFF334155)),
            fontSize: isBold ? 12 : 11,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
