import 'dart:convert';
import '../../utils/constants.dart';
import '../../services/api_services.dart';

class CxpApi {
  final String baseUrl = "$hostName/api/cxp";

  Future<List<dynamic>> getAll(String token) async {
    final api = ApiService();
    final response = await api.get(baseUrl, token: token);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar cuentas por pagar');
  }

  Future<dynamic> registrarPago(String token, int id, Map<String, dynamic> data) async {
    final api = ApiService();
    final response = await api.post("$baseUrl/$id/pagar", data, token: token);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al registrar pago: ${response.body}');
  }

  Future<List<dynamic>> getHistorialPagos(String token) async {
    final api = ApiService();
    final response = await api.get("$baseUrl/pagos/historial", token: token);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar historial de pagos');
  }
}
