import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../palletes/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import '../../models/cxc.dart';
import '../../providers/cxc_provider.dart';
import '../../../utils/helpers.dart';
import '../../../facturacion/models/metodo_pago.dart';
import '../../../facturacion/providers/metodo_pago_provider.dart';

class CxcDetalleCobroPanel extends ConsumerStatefulWidget {
  final CuentaPorCobrar? cxc;
  final VoidCallback onCobroCompletado;

  const CxcDetalleCobroPanel({
    super.key,
    required this.cxc,
    required this.onCobroCompletado,
  });

  @override
  ConsumerState<CxcDetalleCobroPanel> createState() => _CxcDetalleCobroPanelState();
}

class _CxcDetalleCobroPanelState extends ConsumerState<CxcDetalleCobroPanel> {
  final _montoCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  MetodoPago? _metodoPagoSeleccionado;
  bool _isProcessing = false;

  @override
  void didUpdateWidget(covariant CxcDetalleCobroPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cxc != oldWidget.cxc && widget.cxc != null) {
      _montoCtrl.text = widget.cxc!.balancePendiente.toStringAsFixed(2);
      _refCtrl.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.cxc != null) {
      _montoCtrl.text = widget.cxc!.balancePendiente.toStringAsFixed(2);
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

  void _asignarMontoRapido(double porcentaje) {
    if (widget.cxc == null) return;
    final total = widget.cxc!.balancePendiente;
    final monto = total * porcentaje;
    setState(() {
      _montoCtrl.text = monto.toStringAsFixed(2);
    });
  }

  Future<void> _procesarCobro() async {
    final cxc = widget.cxc;
    if (cxc == null) return;

    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    if (monto <= 0) {
      showToast(context, 'Ingrese un monto mayor a cero', bgColor: Colors.red);
      return;
    }
    if (monto > cxc.balancePendiente) {
      showToast(context, 'El monto no puede superar el balance pendiente', bgColor: Colors.red);
      return;
    }

    setState(() => _isProcessing = true);

    final data = {
      'monto_pagado': monto,
      'fecha_pago': DateTime.now().toIso8601String().split('T')[0],
      'metodo_pago_id': _metodoPagoSeleccionado?.id,
      'referencia': _refCtrl.text.trim(),
    };

    try {
      final success = await ref.read(cxcProvider.notifier).registrarPago(cxc.id, data);
      if (success && mounted) {
        showToast(
          context,
          'Cobro de ${FormatterNumber.formatCurrency(monto)} registrado correctamente',
          bgColor: const Color(0xFF059669),
        );
        widget.onCobroCompletado();
      } else if (mounted) {
        showToast(context, 'Error al registrar el cobro', bgColor: Colors.red);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Error: $e', bgColor: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estado sin selección
    if (widget.cxc == null) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.azulOscuro.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 28,
                  color: AppColors.azulOscuro,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Seleccione una cuenta por cobrar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Haga clic en una factura del listado izquierdo para ver los detalles del comprobante y registrar cobros.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
              ),
            ],
          ),
        ),
      );
    }

    final cxc = widget.cxc!;
    final factura = cxc.factura;
    final clienteNombre = cxc.cliente?['nombre'] ?? 'Cliente General';
    final ncf = factura?['ncf'] ?? 'N/A';
    final numFactura = factura?['numero'] ?? '';
    final rncCliente = cxc.cliente?['rnc_cedula'] ?? '';
    final telefonoCliente = cxc.cliente?['telefono'] ?? '';

    final subtotal = double.tryParse(factura?['subtotal']?.toString() ?? '0') ?? 0;
    final itbis = double.tryParse(factura?['itbis']?.toString() ?? '0') ?? 0;
    final totalFactura = double.tryParse(factura?['total']?.toString() ?? '0') ?? cxc.montoOriginal;
    final pagadoAnteriormente = (cxc.montoOriginal - cxc.balancePendiente).clamp(0.0, cxc.montoOriginal);

    final now = DateTime.now();
    final isVencida = cxc.fechaVencimiento != null && cxc.fechaVencimiento!.isBefore(now);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. CABECERA ELEGANTE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.azulOscuro.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.azulOscuro, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clienteNombre,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Factura NCF $ncf ${numFactura.isNotEmpty ? "• #$numFactura" : ""}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de Estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVencida
                        ? const Color(0xFFFEF2F2)
                        : (pagadoAnteriormente > 0 ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isVencida
                          ? const Color(0xFFFCA5A5)
                          : (pagadoAnteriormente > 0 ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
                    ),
                  ),
                  child: Text(
                    isVencida
                        ? 'VENCIDA'
                        : (pagadoAnteriormente > 0 ? 'PAGO PARCIAL' : 'PENDIENTE'),
                    style: TextStyle(
                      color: isVencida
                          ? const Color(0xFFDC2626)
                          : (pagadoAnteriormente > 0 ? const Color(0xFF2563EB) : const Color(0xFFD97706)),
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. DETALLE DE FACTURA / VENTA (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Datos del cliente si están disponibles
                  if (rncCliente.isNotEmpty || telefonoCliente.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          if (rncCliente.isNotEmpty) ...[
                            const Icon(Icons.badge_outlined, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text('RNC: $rncCliente', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                            const SizedBox(width: 12),
                          ],
                          if (telefonoCliente.isNotEmpty) ...[
                            const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(telefonoCliente, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Título Sección Detalle
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 13, color: AppColors.azulOscuro),
                      const SizedBox(width: 6),
                      const Text(
                        'ARTÍCULOS DE LA VENTA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF475569),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Lista / Tabla de Productos
                  if (factura != null && factura['detalles'] != null && (factura['detalles'] as List).isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          // Cabecera de la tabla
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 5, child: Text('DESCRIPCIÓN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                                Expanded(flex: 2, child: Text('CANT.', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                                Expanded(flex: 3, child: Text('PRECIO', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                                Expanded(flex: 3, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                              ],
                            ),
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                          // Filas de artículos
                          ...List.generate(factura['detalles'].length, (index) {
                            final d = factura['detalles'][index];
                            final nombre = d['producto']?['nombre'] ?? d['descripcion'] ?? 'Artículo';
                            final cant = d['cantidad'] ?? 1;
                            final precio = double.tryParse(d['precio'].toString()) ?? 0;
                            final total = double.tryParse(d['total'].toString()) ?? 0;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              color: index.isOdd ? const Color(0xFFFAFAFA) : Colors.white,
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
                                      '$cant',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      FormatterNumber.formatCurrency(precio),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      FormatterNumber.formatCurrency(total),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        cxc.descripcion ?? 'Sin detalle desglosado disponible',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Resumen de Totales y Saldos
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildTotalRow('Subtotal:', FormatterNumber.formatCurrency(subtotal)),
                        const SizedBox(height: 3),
                        _buildTotalRow('Impuestos (ITBIS):', FormatterNumber.formatCurrency(itbis)),
                        const SizedBox(height: 3),
                        _buildTotalRow('Total Facturado:', FormatterNumber.formatCurrency(totalFactura), isBold: true),
                        if (pagadoAnteriormente > 0) ...[
                          const SizedBox(height: 3),
                          _buildTotalRow('Abonos Registrados:', '- ${FormatterNumber.formatCurrency(pagadoAnteriormente)}', color: const Color(0xFF2563EB)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. FORMULARIO REGISTRAR COBRO
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Balance Pendiente
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monetization_on_outlined, size: 16, color: Color(0xFF059669)),
                          SizedBox(width: 6),
                          Text(
                            'BALANCE PENDIENTE',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        FormatterNumber.formatCurrency(cxc.balancePendiente),
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Atajos rápidos de Monto
                Row(
                  children: [
                    _buildQuickAmountButton('100% Saldo Total', 1.0),
                    const SizedBox(width: 6),
                    _buildQuickAmountButton('50% Mitad', 0.5),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _montoCtrl.clear()),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Limpiar', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Inputs: Monto y Método de Pago
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monto a Cobrar
                    Expanded(
                      flex: 4,
                      child: CustomTextField(
                        controller: _montoCtrl,
                        label: 'Monto a Cobrar',
                        prefixIcon: Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Selector de Método de Pago
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Método de Pago',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Consumer(
                            builder: (context, ref, child) {
                              final metodoProv = ref.watch(metodoPagoProvider);
                              final metodos = metodoProv.metodos.where((m) => m.activo).toList();

                              if (metodoProv.isLoading) {
                                return const SizedBox(
                                  height: 38,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                );
                              }

                              if (metodos.isEmpty) {
                                return Container(
                                  height: 38,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFCA5A5)),
                                  ),
                                  child: const Text(
                                    'Sin métodos activos',
                                    style: TextStyle(color: Color(0xFFDC2626), fontSize: 11),
                                  ),
                                );
                              }

                              return DropdownButtonFormField<MetodoPago>(
                                initialValue: _metodoPagoSeleccionado,
                                isExpanded: true,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
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
                              );
                            },
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
                  hintText: 'Ej. Depósito #12345 o Autorización POS...',
                  prefixIcon: Icons.receipt_long_outlined,
                ),

                const SizedBox(height: 12),

                // Botón Confirmar Cobro
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _procesarCobro,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: Text(
                      _isProcessing ? 'Procesando Cobro...' : 'CONFIRMAR COBRO',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
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
