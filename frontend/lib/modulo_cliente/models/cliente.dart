// To parse this JSON data, do
//
//     final cliente = clienteFromJson(jsonString);

import 'dart:convert';

List<Cliente> clienteFromJson(String str) =>
    List<Cliente>.from(json.decode(str).map((x) => Cliente.fromJson(x)));

String clienteToJson(List<Cliente> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Cliente {
  final int? id;
  final String? nombre;
  final String? rncCedula;
  final String? email;
  final String? telefono;
  final String? direccion;
  final String? tipoCliente;
  final double? limiteCredito;
  final double? saldoActual;
  final int? diasCredito;
  final String? cuentaContable;
  final double? descuentoFijo;
  final bool? activo;
  final String? notas;
  final String? createdAt;
  final String? updatedAt;

  Cliente({
    this.id,
    this.nombre,
    this.rncCedula,
    this.email,
    this.telefono,
    this.direccion,
    this.tipoCliente,
    this.limiteCredito,
    this.saldoActual,
    this.diasCredito,
    this.cuentaContable,
    this.descuentoFijo,
    this.activo,
    this.notas,
    this.createdAt,
    this.updatedAt,
  });

  Cliente copyWith({
    int? id,
    String? nombre,
    String? rncCedula,
    String? email,
    String? telefono,
    String? direccion,
    String? tipoCliente,
    double? limiteCredito,
    double? saldoActual,
    int? diasCredito,
    String? cuentaContable,
    double? descuentoFijo,
    bool? activo,
    String? notas,
    String? createdAt,
    String? updatedAt,
  }) => Cliente(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    rncCedula: rncCedula ?? this.rncCedula,
    email: email ?? this.email,
    telefono: telefono ?? this.telefono,
    direccion: direccion ?? this.direccion,
    tipoCliente: tipoCliente ?? this.tipoCliente,
    limiteCredito: limiteCredito ?? this.limiteCredito,
    saldoActual: saldoActual ?? this.saldoActual,
    diasCredito: diasCredito ?? this.diasCredito,
    cuentaContable: cuentaContable ?? this.cuentaContable,
    descuentoFijo: descuentoFijo ?? this.descuentoFijo,
    activo: activo ?? this.activo,
    notas: notas ?? this.notas,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
    id: json["id"],
    nombre: json["nombre"],
    rncCedula: json["rnc_cedula"],
    email: json["email"],
    telefono: json["telefono"],
    direccion: json["direccion"],
    tipoCliente: json["tipo_cliente"],
    limiteCredito: json["limite_credito"] != null
        ? double.tryParse(json["limite_credito"].toString())
        : 0.0,
    saldoActual: json["saldo_actual"] != null
        ? double.tryParse(json["saldo_actual"].toString())
        : 0.0,
    diasCredito: json["dias_credito"],
    cuentaContable: json["cuenta_contable"],
    descuentoFijo: json["descuento_fijo"] != null
        ? double.tryParse(json["descuento_fijo"].toString())
        : 0.0,
    activo: json["activo"] == 1 || json["activo"] == true,
    notas: json["notas"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "nombre": nombre,
    "rnc_cedula": rncCedula,
    "email": email,
    "telefono": telefono,
    "direccion": direccion,
    "tipo_cliente": tipoCliente,
    "limite_credito": limiteCredito,
    "saldo_actual": saldoActual,
    "dias_credito": diasCredito,
    "cuenta_contable": cuentaContable,
    "descuento_fijo": descuentoFijo,
    "activo": activo,
    "notas": notas,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };

  static List<String> getUniqueNombre(List<Cliente> list) {
    return list.map((element) => element.nombre!).toSet().toList();
  }
}
