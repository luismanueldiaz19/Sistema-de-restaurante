import 'dart:convert';
import 'nomina_detalle_model.dart';

class NominaModel {
  final int? id;
  final String periodo; // Ejemplo: "2024-05"
  final DateTime fechaCreacion;
  final String estado; // "Borrador", "Pagada", "Cancelada"
  final double totalBruto;
  final double totalRetenciones;
  final double totalNeto;
  final List<NominaDetalleModel> detalles;

  NominaModel({
    this.id,
    required this.periodo,
    required this.fechaCreacion,
    this.estado = "Borrador",
    this.totalBruto = 0.0,
    this.totalRetenciones = 0.0,
    this.totalNeto = 0.0,
    this.detalles = const [],
  });

  factory NominaModel.fromRawJson(String str) => NominaModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory NominaModel.fromJson(Map<String, dynamic> json) {
    double parse(dynamic value) {
      if (value is String) return double.tryParse(value) ?? 0.0;
      return value?.toDouble() ?? 0.0;
    }

    return NominaModel(
      id: json["id"],
      periodo: json["periodo"],
      fechaCreacion: DateTime.parse(json["fecha_creacion"]),
      estado: json["estado"],
      totalBruto: parse(json["total_bruto"]),
      totalRetenciones: parse(json["total_retenciones"]),
      totalNeto: parse(json["total_neto"]),
      detalles: json["detalles"] == null
          ? []
          : List<NominaDetalleModel>.from(
              json["detalles"].map((x) => NominaDetalleModel.fromJson(x)),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "periodo": periodo,
        "fecha_creacion": fechaCreacion.toIso8601String(),
        "estado": estado,
        "total_bruto": totalBruto,
        "total_retenciones": totalRetenciones,
        "total_neto": totalNeto,
        "detalles": List<dynamic>.from(detalles.map((x) => x.toJson())),
      };
}
