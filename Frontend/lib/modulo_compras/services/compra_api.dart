import 'dart:convert';
import '../../utils/constants.dart';
import '../../services/api_services.dart';

class CompraApi {
  final String baseUrl = "$hostName/api/compras";

  Future<List<dynamic>> getAll(String token) async {
    final api = ApiService();
    final response = await api.get(baseUrl, token: token);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar compras');
  }

  Future<dynamic> create(String token, Map<String, dynamic> data) async {
    final api = ApiService();
    final response = await api.post(baseUrl, data, token: token);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al registrar compra: ${response.body}');
  }
}
