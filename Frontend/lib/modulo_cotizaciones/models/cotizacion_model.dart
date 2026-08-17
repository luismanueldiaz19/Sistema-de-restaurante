import 'dart:convert';
import 'package:sistema_restaurante/model/user.dart';
import 'package:sistema_restaurante/modulo_cliente/models/cliente.dart';

class Cotizacion {
  final int? id;
  final int? clienteId;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final String? subtotal;
  final String? descuentoTotal;
  final String? itbis;
  final String? total;
  final String? estado;
  final String? nota;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? userId;
  final Cliente? cliente;
  final List<CotizacionDetalle>? detalles;
  final User? user;
  final String? pdfUrl;

  Cotizacion({
    this.id,
    this.clienteId,
    this.fechaEmision,
    this.fechaVencimiento,
    this.subtotal,
    this.descuentoTotal,
    this.itbis,
    this.total,
    this.estado,
    this.nota,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.cliente,
    this.detalles,
    this.user,
    this.pdfUrl,
  });

  factory Cotizacion.fromJson(Map<String, dynamic> json) => Cotizacion(
    id: json["id"],
    clienteId: json["cliente_id"],
    fechaEmision: json["fecha_emision"] != null ? DateTime.parse(json["fecha_emision"]) : null,
    fechaVencimiento: json["fecha_vencimiento"] != null ? DateTime.parse(json["fecha_vencimiento"]) : null,
    subtotal: json["subtotal"]?.toString(),
    descuentoTotal: json["descuento_total"]?.toString(),
    itbis: json["itbis"]?.toString(),
    total: json["total"]?.toString(),
    estado: json["estado"],
    nota: json["nota"],
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
    userId: json["user_id"],
    cliente: json["cliente"] != null ? Cliente.fromJson(json["cliente"]) : null,
    detalles: json["detalles"] != null
        ? List<CotizacionDetalle>.from(json["detalles"].map((x) => CotizacionDetalle.fromJson(x)))
        : [],
    user: json["user"] != null ? User.fromJson(json["user"]) : null,
    pdfUrl: json["pdf_url"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "cliente_id": clienteId,
    "fecha_emision": "${fechaEmision?.year.toString().padLeft(4, '0')}-${fechaEmision?.month.toString().padLeft(2, '0')}-${fechaEmision?.day.toString().padLeft(2, '0')}",
    "fecha_vencimiento": "${fechaVencimiento?.year.toString().padLeft(4, '0')}-${fechaVencimiento?.month.toString().padLeft(2, '0')}-${fechaVencimiento?.day.toString().padLeft(2, '0')}",
    "subtotal": subtotal,
    "descuento_total": descuentoTotal,
    "itbis": itbis,
    "total": total,
    "estado": estado,
    "nota": nota,
    "user_id": userId,
    "detalles": detalles != null ? List<dynamic>.from(detalles!.map((x) => x.toJson())) : [],
  };
}

class CotizacionDetalle {
  final int? id;
  final int? cotizacionId;
  final int? productoId;
  final String? descripcion;
  final String? cantidad;
  final String? precio;
  final String? itbis;
  final String? total;

  CotizacionDetalle({
    this.id,
    this.cotizacionId,
    this.productoId,
    this.descripcion,
    this.cantidad,
    this.precio,
    this.itbis,
    this.total,
  });

  factory CotizacionDetalle.fromJson(Map<String, dynamic> json) => CotizacionDetalle(
    id: json["id"],
    cotizacionId: json["cotizacion_id"],
    productoId: json["producto_id"],
    descripcion: json["descripcion"],
    cantidad: json["cantidad"]?.toString(),
    precio: json["precio"]?.toString(),
    itbis: json["itbis"]?.toString(),
    total: json["total"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "cotizacion_id": cotizacionId,
    "producto_id": productoId,
    "descripcion": descripcion,
    "cantidad": cantidad,
    "precio": precio,
    "itbis": itbis,
    "total": total,
  };
}
