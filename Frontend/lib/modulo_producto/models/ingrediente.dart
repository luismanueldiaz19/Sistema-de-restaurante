class Ingrediente {
  final int? id;
  final String nombre;
  final String? unidad;
  final double stock;
  final double costoUnitario;

  Ingrediente({
    this.id,
    required this.nombre,
    this.unidad,
    this.stock = 0,
    this.costoUnitario = 0,
  });

  factory Ingrediente.fromJson(Map<String, dynamic> json) => Ingrediente(
    id: json["id"],
    nombre: json["nombre"],
    unidad: json["unidad"],
    stock: json["stock"]?.toDouble() ?? 0,
    costoUnitario: json["costo_unitario"]?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "nombre": nombre,
    "unidad": unidad,
    "stock": stock,
    "costo_unitario": costoUnitario,
  };
}
