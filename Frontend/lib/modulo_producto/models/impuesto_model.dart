class ImpuestoModel {
  final int id;
  final String nombre;
  final double tasa;
  final bool activo;

  ImpuestoModel({
    required this.id,
    required this.nombre,
    required this.tasa,
    required this.activo,
  });

  factory ImpuestoModel.fromJson(Map<String, dynamic> json) {
    return ImpuestoModel(
      id: json['id'],
      nombre: json['nombre'],
      tasa: double.tryParse(json['tasa'].toString()) ?? 0.0,
      activo: json['activo'] == 1 || json['activo'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tasa': tasa,
      'activo': activo,
    };
  }
}
