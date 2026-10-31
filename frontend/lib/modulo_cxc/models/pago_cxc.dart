class PagoCxc {
  final int id;
  final int cxcId;
  final double montoPagado;
  final String fechaPago;
  final String metodoPago;
  final String? referencia;
  final Map<String, dynamic>? usuario;
  final Map<String, dynamic>? cuentaDestino;
  final Map<String, dynamic>? cuentaPorCobrar;

  PagoCxc({
    required this.id,
    required this.cxcId,
    required this.montoPagado,
    required this.fechaPago,
    required this.metodoPago,
    this.referencia,
    this.usuario,
    this.cuentaDestino,
    this.cuentaPorCobrar,
  });

  factory PagoCxc.fromJson(Map<String, dynamic> json) {
    return PagoCxc(
      id: json['id'],
      cxcId: json['cxc_id'],
      montoPagado: double.tryParse(json['monto_pagado']?.toString() ?? '0') ?? 0,
      fechaPago: json['fecha_pago'] ?? '',
      metodoPago: json['metodo_pago'] ?? 'Desconocido',
      referencia: json['referencia'],
      usuario: json['usuario'],
      cuentaDestino: json['cuenta_destino'],
      cuentaPorCobrar: json['cuenta_por_cobrar'],
    );
  }
}
