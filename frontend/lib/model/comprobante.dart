import 'dart:convert';

List<Comprobante> comprobanteFromJson(String str) => List<Comprobante>.from(
  json.decode(str).map((x) => Comprobante.fromJson(x)),
);

String comprobanteToJson(List<Comprobante> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Comprobante {
  final int id;
  final String tipo;
  final String nombre;
  final String prefijo;

  Comprobante({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.prefijo,
  });

  Comprobante copyWith({
    int? id,
    String? tipo,
    String? nombre,
    String? prefijo,
  }) => Comprobante(
    id: id ?? this.id,
    tipo: tipo ?? this.tipo,
    nombre: nombre ?? this.nombre,
    prefijo: prefijo ?? this.prefijo,
  );

  factory Comprobante.fromJson(Map<String, dynamic> json) => Comprobante(
    id: json["id"],
    tipo: json["tipo"],
    nombre: json["nombre"],
    prefijo: json["prefijo"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "tipo": tipo,
    "nombre": nombre,
    "prefijo": prefijo,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comprobante && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
