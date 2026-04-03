import 'dart:convert';

import '../model/factura.dart';
import '../services/api_services.dart';

class FacturaRepository {
  final ApiService api = ApiService();

  final String baseUrl = "http://127.0.0.1:8000/api";

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
