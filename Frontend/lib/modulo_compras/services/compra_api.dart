import 'dart:convert';
import '../../utils/constants.dart';
import '../../services/api_services.dart';

class CompraApi {
  final String baseUrl = "$apiUrl/compras";

  Future<Map<String, dynamic>> getAll(
    String token, {
    String? fechaDesde,
    String? fechaHasta,
    String? estado,
    String? search,
    int page = 1,
  }) async {
    final api = ApiService();
    String query = '$baseUrl?page=$page';
    if (fechaDesde != null && fechaDesde.isNotEmpty) query += '&fecha_desde=$fechaDesde';
    if (fechaHasta != null && fechaHasta.isNotEmpty) query += '&fecha_hasta=$fechaHasta';
    if (estado != null && estado.isNotEmpty && estado != 'todos') query += '&estado=$estado';
    if (search != null && search.isNotEmpty) query += '&search=$search';
    
    final response = await api.get(query, token: token);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? {};
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
