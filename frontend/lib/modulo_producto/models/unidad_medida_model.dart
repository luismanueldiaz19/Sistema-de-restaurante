class UnidadMedidaModel {
  final int id;
  final String nombre;
  final String? abreviatura;
  final bool activo;

  UnidadMedidaModel({
    required this.id,
    required this.nombre,
    this.abreviatura,
    required this.activo,
  });

  factory UnidadMedidaModel.fromJson(Map<String, dynamic> json) {
    return UnidadMedidaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      abreviatura: json['abreviatura']?.toString(),
      activo: json['activo'] == 1 || json['activo'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'abreviatura': abreviatura,
      'activo': activo,
    };
  }
}
