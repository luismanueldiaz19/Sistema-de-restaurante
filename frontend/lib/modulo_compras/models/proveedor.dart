class Proveedor {
  final int id;
  final String nombre;
  final String? rnc;
  final String? telefono;
  final String? email;
  final String? direccion;
  final int? cuentaContableCxpId;
  final int? cuentaContableGastoId;
  final bool activo;
  final bool esInformal;

  Proveedor({
    required this.id,
    required this.nombre,
    this.rnc,
    this.telefono,
    this.email,
    this.direccion,
    this.cuentaContableCxpId,
    this.cuentaContableGastoId,
    required this.activo,
    this.esInformal = false,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'],
      nombre: json['nombre'],
      rnc: json['rnc'],
      telefono: json['telefono'],
      email: json['email'],
      direccion: json['direccion'],
      cuentaContableCxpId: json['cuenta_contable_cxp_id'],
      cuentaContableGastoId: json['cuenta_contable_gasto_id'],
      activo:
          json['activo'] == 1 ||
          json['activo'] == true ||
          json['activo'] == '1',
      esInformal:
          json['es_informal'] == 1 ||
          json['es_informal'] == true ||
          json['es_informal'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'rnc': rnc,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'cuenta_contable_cxp_id': cuentaContableCxpId,
      'cuenta_contable_gasto_id': cuentaContableGastoId,
      'activo': activo,
      'es_informal': esInformal,
    };
  }
}
