class MetodoPago {
  final int id;
  final String nombre;
  final String tipo;
  final int? catalogoCuentaId;
  final bool activo;
  final dynamic cuentaContable; // Puede ser un modelo de cuenta, por ahora dynamic

  MetodoPago({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.catalogoCuentaId,
    required this.activo,
    this.cuentaContable,
  });

  factory MetodoPago.fromJson(Map<String, dynamic> json) {
    return MetodoPago(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? 'efectivo',
      catalogoCuentaId: json['catalogo_cuenta_id'],
      activo: json['activo'] == 1 || json['activo'] == true,
      cuentaContable: json['cuenta_contable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'catalogo_cuenta_id': catalogoCuentaId,
      'activo': activo,
    };
  }
}
