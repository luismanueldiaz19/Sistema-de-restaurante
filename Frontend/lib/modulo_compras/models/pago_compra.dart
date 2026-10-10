class PagoCompra {
  final int id;
  final int cxpId;
  final double montoPagado;
  final String fechaPago;
  final String metodoPago;
  final int? metodoPagoId;
  final String referencia;
  final String proveedorNombre;
  final String numeroFactura;
  final String bancoNombre;

  PagoCompra({
    required this.id,
    required this.cxpId,
    required this.montoPagado,
    required this.fechaPago,
    required this.metodoPago,
    this.metodoPagoId,
    required this.referencia,
    required this.proveedorNombre,
    required this.numeroFactura,
    required this.bancoNombre,
  });

  factory PagoCompra.fromJson(Map<String, dynamic> json) {
    return PagoCompra(
      id: json['id'] ?? 0,
      cxpId: json['cxp_id'] ?? 0,
      montoPagado:
          double.tryParse(json['monto_pagado']?.toString() ?? '0') ?? 0.0,
      fechaPago: json['fecha_pago']?.toString() ?? '',
      metodoPago: json['metodo_pago'] is Map
          ? (json['metodo_pago']['nombre']?.toString() ?? 'N/A')
          : (json['metodo_pago']?.toString() ?? 'N/A'),
      metodoPagoId: json['metodo_pago_id'] != null
          ? int.tryParse(json['metodo_pago_id'].toString())
          : null,
      referencia: json['referencia']?.toString() ?? 'N/A',
      proveedorNombre:
          json['cuenta_por_pagar']?['proveedor']?['nombre'] ??
          'Proveedor Desconocido',
      numeroFactura:
          json['cuenta_por_pagar']?['compra']?['numero_factura_proveedor'] ??
          'N/A',
      bancoNombre: json['cuenta_origen']?['nombre'] ?? 'Caja/Banco',
    );
  }
}
