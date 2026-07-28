import 'dart:convert';
import '../../utils/constants.dart';
import '../../services/api_services.dart';

class CompraApi {
  final String baseUrl = "$hostName/api/compras";

  Future<List<dynamic>> getAll(String token, {String? fechaDesde, String? fechaHasta}) async {
    final api = ApiService();
    String query = baseUrl;
    if (fechaDesde != null && fechaHasta != null) {
      query += '?fecha_desde=$fechaDesde&fecha_hasta=$fechaHasta';
    }
    
    final response = await api.get(query, token: token);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar compras');
  }

  Future<dynamic> create(String token, Map<String, dynamic> data) async {
    final api = ApiService();
    final response = await api.post(baseUrl, data, token: token);

    // 201 = compra nueva creada exitosamente
    // 200 = respuesta idempotente: el backend detectó el mismo idempotency_key
    //       y devuelve la compra existente sin duplicar ningún registro.
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al registrar compra: ${response.body}');
  }
}
