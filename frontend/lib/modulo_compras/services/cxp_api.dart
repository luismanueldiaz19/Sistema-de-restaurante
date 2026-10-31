import 'dart:convert';
import '../../utils/constants.dart';
import '../../services/api_services.dart';

class CxpApi {
  final String baseUrl = "$apiUrl/cxp";

  Future<List<dynamic>> getAll(String token) async {
    final api = ApiService();
    final response = await api.get(baseUrl, token: token);

    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      if (body is List) return body;
      if (body is Map) {
        return body['data'] is List ? body['data'] : [];
      }
      return [];
    }
    throw Exception('Error al cargar cuentas por pagar: ${response.body}');
  }

  Future<dynamic> registrarPago(
    String token,
    int id,
    Map<String, dynamic> data,
  ) async {
    final api = ApiService();
    final response = await api.post("$baseUrl/$id/pagar", data, token: token);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic body = jsonDecode(response.body);
      if (body is Map) {
        return body['data'] ?? body['pago'] ?? body;
      }
      return body;
    }
    throw Exception('Error al registrar pago: ${response.body}');
  }

  Future<Map<String, dynamic>> getHistorialPagos(String token, {Map<String, dynamic>? filters}) async {
    final api = ApiService();
    String query = "";
    if (filters != null && filters.isNotEmpty) {
      final uri = Uri(queryParameters: filters.map((k, v) => MapEntry(k, v.toString())));
      query = "?${uri.query}";
    }
    final response = await api.get("$baseUrl/pagos/historial$query", token: token);

    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return body['data'] is Map<String, dynamic>
            ? body['data']
            : (body['data'] is List ? {'data': body['data']} : body);
      }
      if (body is List) {
        return {'data': body};
      }
      return {};
    }
    throw Exception('Error al cargar historial de pagos: ${response.body}');
  }

  Future<List<dynamic>> getPagosPorCompra(String token, int compraId) async {
    final api = ApiService();
    final response = await api.get(
      "$baseUrl/compra/$compraId/pagos",
      token: token,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return body['data'] ?? [];
    }
    throw Exception('Error al cargar los pagos de la compra');
  }
}
