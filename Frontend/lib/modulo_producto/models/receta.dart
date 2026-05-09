import 'ingrediente.dart';

class Receta {
  final int? id;
  final int productoId;
  final int ingredienteId;
  final double cantidad;
  final Ingrediente? ingrediente;

  Receta({
    this.id,
    required this.productoId,
    required this.ingredienteId,
    required this.cantidad,
    this.ingrediente,
  });

  factory Receta.fromJson(Map<String, dynamic> json) => Receta(
    id: json["id"],
    productoId: json["producto_id"],
    ingredienteId: json["ingrediente_id"],
    cantidad: json["cantidad"]?.toDouble() ?? 0,
    ingrediente: json["ingrediente"] == null ? null : Ingrediente.fromJson(json["ingrediente"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "producto_id": productoId,
    "ingrediente_id": ingredienteId,
    "cantidad": cantidad,
  };
}
