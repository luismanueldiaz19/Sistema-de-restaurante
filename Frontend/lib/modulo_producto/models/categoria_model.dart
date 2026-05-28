class CategoriaModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  CategoriaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      activo: json['activo'] == 1 || json['activo'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
    };
  }
}
