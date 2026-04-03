class Detalle {
  final int? facturaId;
  final String? descripcion;
  final String? unidadMedida;
  final int? cantidad;
  final double? precio;
  final double? descuento;
  final double? descuentoPorcentaje;
  final double? itbis;
  final double? total;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Detalle({
    this.facturaId,
    this.descripcion,
    this.unidadMedida,
    this.cantidad,
    this.precio,
    this.descuento,
    this.descuentoPorcentaje,
    this.itbis,
    this.total,
    this.createdAt,
    this.updatedAt,
  });

  Detalle copyWith({
    int? facturaId,
    String? descripcion,
    String? unidadMedida,
    int? cantidad,
    double? precio,
    double? descuento,
    double? descuentoPorcentaje,
    double? itbis,
    double? total,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Detalle(
    facturaId: facturaId ?? this.facturaId,
    descripcion: descripcion ?? this.descripcion,
    unidadMedida: unidadMedida ?? this.unidadMedida,
    cantidad: cantidad ?? this.cantidad,
    precio: precio ?? this.precio,
    descuento: descuento ?? this.descuento,
    descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
    itbis: itbis ?? this.itbis,
    total: total ?? this.total,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory Detalle.fromJson(Map<String, dynamic> json) => Detalle(
    facturaId: json["factura_id"],
    descripcion: json["descripcion"],
    unidadMedida: json["unidad_medida"],
    cantidad: json["cantidad"],
    precio: json["precio"],
    descuento: json["descuento"],
    descuentoPorcentaje: json["descuento_porcentaje"],
    itbis: json["itbis"],
    total: json["total"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "factura_id": facturaId,
    "descripcion": descripcion,
    "unidad_medida": unidadMedida,
    "cantidad": cantidad,
    "precio": precio,
    "descuento": descuento,
    "descuento_porcentaje": descuentoPorcentaje,
    "itbis": itbis,
    "total": total,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}
