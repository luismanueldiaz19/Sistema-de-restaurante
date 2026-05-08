class ProductoProvisional {
  final String id;
  final String descripcion;
  final double precio;
  final String unidadMedida;
  final int stock;
  final double itbisPorcentaje;

  ProductoProvisional({
    required this.id,
    required this.descripcion,
    required this.precio,
    this.unidadMedida = 'UNIT',
    this.stock = 0,
    this.itbisPorcentaje = 18.0,
  });

  factory ProductoProvisional.fromJson(Map<String, dynamic> json) {
    return ProductoProvisional(
      id: json['id'].toString(),
      descripcion: json['descripcion'] ?? '',
      precio: (json['precio'] as num).toDouble(),
      unidadMedida: json['unidad_medida'] ?? 'UNIT',
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descripcion': descripcion,
      'precio': precio,
      'unidad_medida': unidadMedida,
      'stock': stock,
    };
  }
}
