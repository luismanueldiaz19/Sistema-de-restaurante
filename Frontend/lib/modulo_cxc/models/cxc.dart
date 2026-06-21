class CuentaPorCobrar {
  final int id;
  final int clienteId;
  final int? facturaId;
  final double montoOriginal;
  final double balancePendiente;
  final DateTime fechaEmision;
  final DateTime? fechaVencimiento;
  final String estado;
  final String? descripcion;
  
  // Relaciones
  final dynamic cliente;
  final dynamic factura;

  CuentaPorCobrar({
    required this.id,
    required this.clienteId,
    this.facturaId,
    required this.montoOriginal,
    required this.balancePendiente,
    required this.fechaEmision,
    this.fechaVencimiento,
    required this.estado,
    this.descripcion,
    this.cliente,
    this.factura,
  });

  factory CuentaPorCobrar.fromJson(Map<String, dynamic> json) {
    return CuentaPorCobrar(
      id: json['id'],
      clienteId: json['cliente_id'],
      facturaId: json['factura_id'],
      montoOriginal: double.tryParse(json['monto_original'].toString()) ?? 0,
      balancePendiente: double.tryParse(json['balance_pendiente'].toString()) ?? 0,
      fechaEmision: DateTime.parse(json['fecha_emision']),
      fechaVencimiento: json['fecha_vencimiento'] != null 
          ? DateTime.parse(json['fecha_vencimiento']) 
          : null,
      estado: json['estado'] ?? 'PENDIENTE',
      descripcion: json['descripcion'],
      cliente: json['cliente'],
      factura: json['factura'],
    );
  }
}
