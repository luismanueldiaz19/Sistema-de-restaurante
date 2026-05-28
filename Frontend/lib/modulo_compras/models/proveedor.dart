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
      activo: json['activo'] == 1 || json['activo'] == true,
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
    };
  }
}
