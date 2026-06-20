import 'dart:convert';
import '../../utils/constants.dart';
import '../../services/api_services.dart';

class ProveedorApi {
  final String baseUrl = "$hostName/api/proveedores";

  Future<List<dynamic>> getAll(String token) async {
    final api = ApiService();
    final response = await api.get(baseUrl, token: token);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar proveedores');
  }

  Future<dynamic> create(String token, Map<String, dynamic> data) async {
    final api = ApiService();
    final response = await api.post(baseUrl, data, token: token);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al crear proveedor: ${response.body}');
  }

  Future<dynamic> update(String token, int id, Map<String, dynamic> data) async {
    final api = ApiService();
    final response = await api.put("$baseUrl/$id", data, token: token);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al actualizar proveedor: ${response.body}');
  }

  Future<void> delete(String token, int id) async {
    final api = ApiService();
    final response = await api.delete("$baseUrl/$id", token: token);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar proveedor: ${response.body}');
    }
  }
}
