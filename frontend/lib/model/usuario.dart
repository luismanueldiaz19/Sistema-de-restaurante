class Usuario {
  final int? id;
  final String? nombre;
  final String? usuario;

  Usuario({required this.id, required this.nombre, this.usuario});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['usuario_id'] is int
          ? json['usuario_id']
          : int.parse(json['usuario_id']),
      nombre: json['nombre'],
      usuario: json['usuario'],
    );
  }

  Map<String, dynamic> toJson() => {
    'usuario_id': id,
    'nombre': nombre,
    'usuario': usuario,
  };
}
