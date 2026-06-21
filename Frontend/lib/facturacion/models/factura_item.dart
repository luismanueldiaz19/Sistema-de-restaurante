class FacturaItem {
  final String id;
  final String descripcion;
  final double precio;
  final double cantidad;
  final double itbisPorcentaje;
  final double descuentoPorcentaje;

  FacturaItem({
    required this.id,
    required this.descripcion,
    required this.precio,
    this.cantidad = 1,
    this.itbisPorcentaje = 18.0, // ITBIS estándar RD
    this.descuentoPorcentaje = 0.0,
  });

  // Cálculos Senior (Precio INCLUYE ITBIS)
  // 1. El valor bruto del ítem (precio con itbis * cantidad)
  double get _valorBruto => precio * cantidad;
  
  // 2. El descuento se aplica sobre el valor bruto
  double get montoDescuento => _valorBruto * (descuentoPorcentaje / 100);
  
  // 3. El total final que pagará el cliente
  double get total => _valorBruto - montoDescuento;
  
  // 4. Extraemos la base imponible (sin itbis) del total final
  double get baseImponible => total / (1 + (itbisPorcentaje / 100));
  
  // 5. El subtotal es la base imponible antes de aplicar el descuento
  // (Asumiendo que el descuento también reduce el ITBIS proporcionalmente)
  double get subtotal => _valorBruto / (1 + (itbisPorcentaje / 100));
  
  // 6. El monto de ITBIS es la diferencia
  double get montoItbis => total - baseImponible;

  FacturaItem copyWith({
    double? cantidad,
    double? descuentoPorcentaje,
    double? precio,
  }) {
    return FacturaItem(
      id: id,
      descripcion: descripcion,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      itbisPorcentaje: itbisPorcentaje,
      descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
    );
  }
}

class TotalesFactura {
  final double subtotal;
  final double descuento;
  final double itbis;
  final double total;

  TotalesFactura({
    required this.subtotal,
    required this.descuento,
    required this.itbis,
    required this.total,
  });

  factory TotalesFactura.zero() =>
      TotalesFactura(subtotal: 0, descuento: 0, itbis: 0, total: 0);
}
