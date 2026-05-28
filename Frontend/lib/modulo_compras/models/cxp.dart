import 'proveedor.dart';
import 'compra.dart';

class CuentaPorPagar {
  final int id;
  final int proveedorId;
  final Proveedor? proveedor;
  final int compraId;
  final Compra? compra;
  final double montoOriginal;
  final double balancePendiente;
  final DateTime fechaVencimiento;
  final String estado;

  CuentaPorPagar({
    required this.id,
    required this.proveedorId,
    this.proveedor,
    required this.compraId,
    this.compra,
    required this.montoOriginal,
    required this.balancePendiente,
    required this.fechaVencimiento,
    required this.estado,
  });

  factory CuentaPorPagar.fromJson(Map<String, dynamic> json) {
    return CuentaPorPagar(
      id: json['id'],
      proveedorId: json['proveedor_id'],
      proveedor: json['proveedor'] != null ? Proveedor.fromJson(json['proveedor']) : null,
      compraId: json['compra_id'],
      compra: json['compra'] != null ? Compra.fromJson(json['compra']) : null,
      montoOriginal: double.tryParse(json['monto_original']?.toString() ?? '0') ?? 0.0,
      balancePendiente: double.tryParse(json['balance_pendiente']?.toString() ?? '0') ?? 0.0,
      fechaVencimiento: DateTime.parse(json['fecha_vencimiento']),
      estado: json['estado'] ?? 'PENDIENTE',
    );
  }
}
