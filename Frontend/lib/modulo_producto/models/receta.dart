import 'producto.dart';

class Receta {
  final int? id;
  final int productoId;
  final int ingredienteProductoId;
  final double cantidad;
  final Producto? ingrediente;

  Receta({
    this.id,
    required this.productoId,
    required this.ingredienteProductoId,
    required this.cantidad,
    this.ingrediente,
  });

  factory Receta.fromJson(Map<String, dynamic> json) => Receta(
    id: json["id"],
    productoId: json["producto_id"],
    ingredienteProductoId: json["ingrediente_producto_id"],
    cantidad: json["cantidad"]?.toDouble() ?? 0,
    ingrediente: json["ingrediente"] == null ? null : Producto.fromJson(json["ingrediente"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "producto_id": productoId,
    "ingrediente_producto_id": ingredienteProductoId,
    "cantidad": cantidad,
  };
}
