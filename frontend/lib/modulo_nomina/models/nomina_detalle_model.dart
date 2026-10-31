import 'dart:convert';

class NominaDetalleModel {
  final int? id;
  final int? nominaId;
  final int empleadoId;
  final String nombreEmpleado;
  final double salarioBruto;
  final double horasExtras;
  final double incentivos;
  final double feriados;
  final double afpEmpleado;
  final double sfsEmpleado;
  final double isrRetencion;
  final double otrosDescuentos;
  final double salarioNeto;

  NominaDetalleModel({
    this.id,
    this.nominaId,
    required this.empleadoId,
    required this.nombreEmpleado,
    required this.salarioBruto,
    this.horasExtras = 0.0,
    this.incentivos = 0.0,
    this.feriados = 0.0,
    required this.afpEmpleado,
    required this.sfsEmpleado,
    required this.isrRetencion,
    required this.otrosDescuentos,
    required this.salarioNeto,
  });

  factory NominaDetalleModel.fromRawJson(String str) => NominaDetalleModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory NominaDetalleModel.fromJson(Map<String, dynamic> json) {
    double parse(dynamic value) {
      if (value is String) return double.tryParse(value) ?? 0.0;
      return value?.toDouble() ?? 0.0;
    }

    return NominaDetalleModel(
      id: json["id"],
      nominaId: json["nomina_id"],
      empleadoId: json["empleado_id"],
      nombreEmpleado: json["nombre_empleado"] ?? "",
      salarioBruto: parse(json["salario_bruto"]),
      horasExtras: parse(json["horas_extras"]),
      incentivos: parse(json["incentivos"]),
      feriados: parse(json["feriados"]),
      afpEmpleado: parse(json["afp_empleado"]),
      sfsEmpleado: parse(json["sfs_empleado"]),
      isrRetencion: parse(json["isr_retencion"]),
      otrosDescuentos: parse(json["otros_descuentos"]),
      salarioNeto: parse(json["salario_neto"]),
    );
  }

  // Helper factory to handle API mismatches if needed
  static NominaDetalleModel fromJsonFixed(Map<String, dynamic> json) {
    double parse(dynamic value) {
      if (value is String) return double.tryParse(value) ?? 0.0;
      return value?.toDouble() ?? 0.0;
    }
    return NominaDetalleModel(
      id: json["id"],
      nominaId: json["nomina_id"],
      empleadoId: json["empleado_id"],
      nombreEmpleado: json["nombre_empleado"] ?? "",
      salarioBruto: parse(json["salario_bruto"]),
      horasExtras: parse(json["horas_extras"]),
      incentivos: parse(json["incentivos"]),
      feriados: parse(json["feriados"]),
      afpEmpleado: parse(json["afp_empleado"]),
      sfsEmpleado: parse(json["sfs_empleado"]),
      isrRetencion: parse(json["isr_retencion"]),
      otrosDescuentos: parse(json["otros_descuentos"]),
      salarioNeto: parse(json["salario_neto"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "nomina_id": nominaId,
        "empleado_id": empleadoId,
        "nombre_empleado": nombreEmpleado,
        "salario_bruto": salarioBruto,
        "horas_extras": horasExtras,
        "incentivos": incentivos,
        "feriados": feriados,
        "afp_empleado": afpEmpleado,
        "sfs_empleado": sfsEmpleado,
        "isr_retencion": isrRetencion,
        "otros_descuentos": otrosDescuentos,
        "salario_neto": salarioNeto,
      };
}
