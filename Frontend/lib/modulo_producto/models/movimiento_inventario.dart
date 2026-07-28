import 'producto.dart';

class MovimientoInventario {
  final int? id;
  final int? productoId;
  final String? tipo;
  final double? cantidad;
  final String? referencia;
  final DateTime? fecha;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Producto? producto;

  MovimientoInventario({
    this.id,
    this.productoId,
    this.tipo,
    this.cantidad,
    this.referencia,
    this.fecha,
    this.createdAt,
    this.updatedAt,
    this.producto,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) => MovimientoInventario(
        id: json['id'],
        productoId: json['producto_id'],
        tipo: json['tipo'],
        cantidad: json['cantidad'] != null ? (json['cantidad'] as num).toDouble() : null,
        referencia: json['referencia'],
        fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha']) : null,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
        producto: json['producto'] != null ? Producto.fromJson(json['producto']) : null,
      );
}
