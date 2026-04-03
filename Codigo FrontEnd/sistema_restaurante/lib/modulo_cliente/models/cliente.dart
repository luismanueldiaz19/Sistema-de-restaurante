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
  final String? telefono;
  final String? direccion;
  final String? documento;
  final String? email;
  final String? createdAt;
  final String? updatedAt;

  Cliente({
    this.id,
    this.nombre,
    this.telefono,
    this.direccion,
    this.documento,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  Cliente copyWith({
    int? id,
    String? nombre,
    String? telefono,
    String? direccion,
    String? documento,
    String? email,
    String? createdAt,
    String? updatedAt,
  }) => Cliente(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    telefono: telefono ?? this.telefono,
    direccion: direccion ?? this.direccion,
    documento: documento ?? this.documento,
    email: email ?? this.email,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
    id: json["id"],
    nombre: json["nombre"],
    telefono: json["telefono"],
    direccion: json["direccion"],
    documento: json["documento"],
    email: json["email"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "nombre": nombre,
    "telefono": telefono,
    "direccion": direccion,
    "documento": documento,
    "email": email,
    "created_at": createdAt.toString(),
    "updated_at": updatedAt.toString(),
  };
}
