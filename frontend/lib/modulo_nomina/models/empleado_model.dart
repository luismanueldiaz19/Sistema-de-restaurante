import 'dart:convert';

class EmpleadoModel {
  final int? id;
  final String nombre;
  final String cedula;
  final double salarioBase;
  final String tipoNomina; // Semanal, Quincenal, Mensual
  final String? turno;     // Mañana, Tarde, Noche, etc.
  final DateTime fechaIngreso;
  final String? cargo;
  final bool activo;

  EmpleadoModel({
    this.id,
    required this.nombre,
    required this.cedula,
    required this.salarioBase,
    this.tipoNomina = 'Mensual',
    this.turno,
    required this.fechaIngreso,
    this.cargo,
    this.activo = true,
  });

  factory EmpleadoModel.fromRawJson(String str) => EmpleadoModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory EmpleadoModel.fromJson(Map<String, dynamic> json) => EmpleadoModel(
        id: json["id"],
        nombre: json["nombre"],
        cedula: json["cedula"],
        salarioBase: json["salario_base"] is String
            ? double.tryParse(json["salario_base"]) ?? 0.0
            : (json["salario_base"]?.toDouble() ?? 0.0),
        tipoNomina: json["tipo_nomina"] ?? "Mensual",
        turno: json["turno"],
        fechaIngreso: DateTime.parse(json["fecha_ingreso"]),
        cargo: json["cargo"],
        activo: (json["activo"] is int) ? json["activo"] == 1 : (json["activo"] ?? true),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "nombre": nombre,
        "cedula": cedula,
        "salario_base": salarioBase,
        "tipo_nomina": tipoNomina,
        "turno": turno,
        "fecha_ingreso":
            "${fechaIngreso.year.toString().padLeft(4, '0')}-${fechaIngreso.month.toString().padLeft(2, '0')}-${fechaIngreso.day.toString().padLeft(2, '0')}",
        "cargo": cargo,
        "activo": activo,
      };

  EmpleadoModel copyWith({
    int? id,
    String? nombre,
    String? cedula,
    double? salarioBase,
    String? tipoNomina,
    String? turno,
    DateTime? fechaIngreso,
    String? cargo,
    bool? activo,
  }) =>
      EmpleadoModel(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        cedula: cedula ?? this.cedula,
        salarioBase: salarioBase ?? this.salarioBase,
        tipoNomina: tipoNomina ?? this.tipoNomina,
        turno: turno ?? this.turno,
        fechaIngreso: fechaIngreso ?? this.fechaIngreso,
        cargo: cargo ?? this.cargo,
        activo: activo ?? this.activo,
      );
}
