import 'package:flutter/material.dart';
import 'package:sistema_restaurante/model/detalle.dart';

import '../model/factura.dart';
import '../repositories/repo_factura.dart';

class FacturaProvider with ChangeNotifier {
  final FacturaRepository _repo = FacturaRepository();

  bool _isLoading = false;
  String? _error;
  int? _facturaId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get facturaId => _facturaId;

  Future<void> crearFactura(Factura factura, token) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      final response = await _repo.crearFactura(factura, token);
      _facturaId = response['factura_id'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

Future crearFactur(context) async {
  final provider = context.read<FacturaProvider>();

  await provider.crearFactura(
    Factura(
      clienteId: 8,
      ncf: "B0100000002",
      fechaEmision: DateTime.parse("2026-04-03"),
      fechaVencimiento: DateTime.parse("2026-04-10"),
      userId: 2,
      detalles: [
        Detalle(
          descripcion: "Zapatos",
          unidadMedida: "CAJA",
          cantidad: 2,
          precio: 500,
          descuento: 50,
        ),
      ],
    ),
  );
}
