import '../../modulo_cliente/models/cliente.dart';

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

  // Cálculos Senior
  double get subtotal => precio * cantidad;
  double get montoDescuento => subtotal * (descuentoPorcentaje / 100);
  double get baseImponible => subtotal - montoDescuento;
  double get montoItbis => baseImponible * (itbisPorcentaje / 100);
  double get total => baseImponible + montoItbis;

  FacturaItem copyWith({
    double? cantidad,
    double? descuentoPorcentaje,
  }) {
    return FacturaItem(
      id: id,
      descripcion: descripcion,
      precio: precio,
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

  factory TotalesFactura.zero() => TotalesFactura(subtotal: 0, descuento: 0, itbis: 0, total: 0);
}
