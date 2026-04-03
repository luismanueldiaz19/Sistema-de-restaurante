import 'dart:convert';

import 'package:sistema_restaurante/model/detalle.dart';
import 'package:sistema_restaurante/model/user.dart';

import '../modulo_cliente/models/cliente.dart';

List<Factura> facturaFromJson(String str) =>
    List<Factura>.from(json.decode(str).map((x) => Factura.fromJson(x)));

String facturaToJson(List<Factura> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Factura {
  final int? id;
  final int? clienteId;
  final String? ncf;
  final String? tipoFactura;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final String? subtotal;
  final String? descuentoTotal;
  final String? itbis;
  final String? total;
  final String? estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? userId;
  final Cliente? cliente;
  final List<Detalle>? detalles;
  final User? user;

  Factura({
    this.id,
    this.clienteId,
    this.ncf,
    this.tipoFactura,
    this.fechaEmision,
    this.fechaVencimiento,
    this.subtotal,
    this.descuentoTotal,
    this.itbis,
    this.total,
    this.estado,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.cliente,
    this.detalles,
    this.user,
  });

  Factura copyWith({
    int? id,
    int? clienteId,
    String? ncf,
    String? tipoFactura,
    DateTime? fechaEmision,
    DateTime? fechaVencimiento,
    String? subtotal,
    String? descuentoTotal,
    String? itbis,
    String? total,
    String? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? userId,
    Cliente? cliente,
    List<Detalle>? detalles,
    User? user,
  }) => Factura(
    id: id ?? this.id,
    clienteId: clienteId ?? this.clienteId,
    ncf: ncf ?? this.ncf,
    tipoFactura: tipoFactura ?? this.tipoFactura,
    fechaEmision: fechaEmision ?? this.fechaEmision,
    fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
    subtotal: subtotal ?? this.subtotal,
    descuentoTotal: descuentoTotal ?? this.descuentoTotal,
    itbis: itbis ?? this.itbis,
    total: total ?? this.total,
    estado: estado ?? this.estado,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    userId: userId ?? this.userId,
    cliente: cliente ?? this.cliente,
    detalles: detalles ?? this.detalles,
    user: user ?? this.user,
  );

  factory Factura.fromJson(Map<String, dynamic> json) => Factura(
    id: json["id"],
    clienteId: json["cliente_id"],
    ncf: json["ncf"],
    tipoFactura: json["tipo_factura"],
    fechaEmision: DateTime.parse(json["fecha_emision"]),
    fechaVencimiento: DateTime.parse(json["fecha_vencimiento"]),
    subtotal: json["subtotal"],
    descuentoTotal: json["descuento_total"],
    itbis: json["itbis"],
    total: json["total"],
    estado: json["estado"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    userId: json["user_id"],
    cliente: Cliente.fromJson(json["cliente"]),
    detalles: List<Detalle>.from(
      json["detalles"].map((x) => Detalle.fromJson(x)),
    ),
    user: User.fromJson(json["user"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "cliente_id": clienteId,
    "ncf": ncf,
    "tipo_factura": tipoFactura,
    "fecha_emision":
        "${fechaEmision?.year.toString().padLeft(4, '0')}-${fechaEmision?.month.toString().padLeft(2, '0')}-${fechaEmision?.day.toString().padLeft(2, '0')}",
    "fecha_vencimiento":
        "${fechaVencimiento?.year.toString().padLeft(4, '0')}-${fechaVencimiento?.month.toString().padLeft(2, '0')}-${fechaVencimiento?.day.toString().padLeft(2, '0')}",
    "subtotal": subtotal,
    "descuento_total": descuentoTotal,
    "itbis": itbis,
    "total": total,
    "estado": estado,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "user_id": userId,
    "cliente": cliente?.toJson(),
    "detalles": List<dynamic>.from(detalles!.map((x) => x.toJson())),
    "user": user?.toJson(),
  };
}
