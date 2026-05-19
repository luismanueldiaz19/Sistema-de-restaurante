class CatalogoCuentaModel {
  final int id;
  final String codigo;
  final String nombre;
  final String tipo;
  final int nivel;
  final int? padreId;
  final bool permiteMovimiento;

  CatalogoCuentaModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    required this.nivel,
    this.padreId,
    required this.permiteMovimiento,
  });

  factory CatalogoCuentaModel.fromJson(Map<String, dynamic> json) {
    return CatalogoCuentaModel(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
      nivel: json['nivel'] as int,
      padreId: json['padre_id'] as int?,
      permiteMovimiento: json['permite_movimiento'] == 1 || json['permite_movimiento'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'tipo': tipo,
      'nivel': nivel,
      'padre_id': padreId,
      'permite_movimiento': permiteMovimiento,
    };
  }
}
