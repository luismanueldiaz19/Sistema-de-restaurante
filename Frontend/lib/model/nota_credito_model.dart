import 'package:sistema_restaurante/model/factura.dart';
import 'package:sistema_restaurante/model/detalle.dart';

class NotaCreditoModel {
  final int? id;
  final int? facturaId;
  final String? ncf;
  final String? motivo;
  final String? totalDevolucion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Factura? factura;
  final List<Detalle>? detalles;

  NotaCreditoModel({
    this.id,
    this.facturaId,
    this.ncf,
    this.motivo,
    this.totalDevolucion,
    this.createdAt,
    this.updatedAt,
    this.factura,
    this.detalles,
  });

  factory NotaCreditoModel.fromJson(Map<String, dynamic> json) => NotaCreditoModel(
    id: json["id"],
    facturaId: json["factura_id"],
    ncf: json["ncf"],
    motivo: json["motivo"],
    totalDevolucion: json["total"]?.toString(),
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
    factura: json["factura"] != null ? Factura.fromJson(json["factura"]) : null,
    detalles: json["detalles"] != null
        ? List<Detalle>.from(json["detalles"].map((x) => Detalle.fromJson(x)))
        : [],
  );
}
