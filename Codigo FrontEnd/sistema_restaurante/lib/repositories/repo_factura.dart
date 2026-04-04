import 'dart:convert';

import 'package:sistema_restaurante/utils/constants.dart';

import '../model/factura.dart';
import '../services/api_services.dart';

class FacturaRepository {
  final ApiService api = ApiService();

  final String baseUrl = "http://$ipLocal/api/facturas";

  Future<Map<String, dynamic>> crearFactura(Factura factura, token) async {
    final response = await api.post(baseUrl, factura.toJson(), token: token);
    final data = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      // final res = response.body;
      // final value = jsonDecode(res);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Error al crear factura');
    }
  }
}
