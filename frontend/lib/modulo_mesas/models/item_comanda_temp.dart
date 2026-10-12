class ItemComandaTemp {
  final int productoId;
  final String nombre;
  final double precio;
  double cantidad;

  ItemComandaTemp({
    required this.productoId,
    required this.nombre,
    required this.precio,
    this.cantidad = 1.0,
  });

  double get subtotal => precio * cantidad;

  Map<String, dynamic> toPayload() {
    return {
      'producto_id': productoId,
      'nombre_producto': nombre,
      'cantidad': cantidad,
      'precio_unitario': precio,
    };
  }
}
