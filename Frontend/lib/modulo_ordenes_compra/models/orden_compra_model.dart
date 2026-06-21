import 'package:sistema_restaurante/model/user.dart';
import '../../modulo_compras/models/proveedor.dart';

class OrdenCompra {
  final int? id;
  final int? proveedorId;
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
  final Proveedor? proveedor;
  final List<OrdenCompraDetalle>? detalles;
  final User? user;

  OrdenCompra({
    this.id,
    this.proveedorId,
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
    this.proveedor,
    this.detalles,
    this.user,
  });

  factory OrdenCompra.fromJson(Map<String, dynamic> json) => OrdenCompra(
    id: json["id"],
    proveedorId: json["proveedor_id"],
    fechaEmision: json["fecha_emision"] != null
        ? DateTime.parse(json["fecha_emision"])
        : null,
    fechaVencimiento: json["fecha_vencimiento"] != null
        ? DateTime.parse(json["fecha_vencimiento"])
        : null,
    subtotal: json["subtotal"]?.toString(),
    descuentoTotal: json["descuento_total"]?.toString(),
    itbis: json["itbis"]?.toString(),
    total: json["total"]?.toString(),
    estado: json["estado"],
    nota: json["notas"],
    createdAt: json["created_at"] != null
        ? DateTime.parse(json["created_at"])
        : null,
    updatedAt: json["updated_at"] != null
        ? DateTime.parse(json["updated_at"])
        : null,
    userId: json["user_id"],
    proveedor: json["proveedor"] != null
        ? Proveedor.fromJson(json["proveedor"])
        : null,
    detalles: json["detalles"] != null
        ? List<OrdenCompraDetalle>.from(
            json["detalles"].map((x) => OrdenCompraDetalle.fromJson(x)),
          )
        : [],
    user: json["user"] != null ? User.fromJson(json["user"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "proveedor_id": proveedorId,
    "numero_orden": null, // Optional if we want to store it here
    "fecha_emision":
        "${fechaEmision?.year.toString().padLeft(4, '0')}-${fechaEmision?.month.toString().padLeft(2, '0')}-${fechaEmision?.day.toString().padLeft(2, '0')}",
    "fecha_vencimiento":
        "${fechaVencimiento?.year.toString().padLeft(4, '0')}-${fechaVencimiento?.month.toString().padLeft(2, '0')}-${fechaVencimiento?.day.toString().padLeft(2, '0')}",
    "subtotal": subtotal,
    "descuento_total": descuentoTotal,
    "itbis": itbis,
    "total": total,
    "estado": estado,
    "nota": nota,
    "usuario_id": userId,
    "detalles": detalles != null
        ? List<dynamic>.from(detalles!.map((x) => x.toJson()))
        : [],
  };
}

class OrdenCompraDetalle {
  final int? id;
  final int? OrdenCompraId;
  final int? productoId;
  final String? descripcion;
  final String? cantidad;
  final String? precio;
  final String? itbis;
  final String? total;

  OrdenCompraDetalle({
    this.id,
    this.OrdenCompraId,
    this.productoId,
    this.descripcion,
    this.cantidad,
    this.precio,
    this.itbis,
    this.total,
  });

  factory OrdenCompraDetalle.fromJson(Map<String, dynamic> json) =>
      OrdenCompraDetalle(
        id: json["id"],
        OrdenCompraId: json["orden_compra_id"],
        productoId: json["producto_id"],
        descripcion: json["descripcion"],
        cantidad: json["cantidad"]?.toString(),
        precio: (json["costo_esperado"] ?? json["precio"])?.toString(),
        itbis: json["itbis"]?.toString(),
        total: json["total"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "orden_compra_id": OrdenCompraId,
    "producto_id": productoId,
    "descripcion": descripcion,
    "cantidad": cantidad,
    "precio": precio,
    "itbis": itbis,
    "total": total,
  };
}
