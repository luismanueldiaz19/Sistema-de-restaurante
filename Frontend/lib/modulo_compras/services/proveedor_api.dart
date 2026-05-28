import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class ProveedorApi {
  final String baseUrl = "$hostName/api/proveedores";

  Future<List<dynamic>> getAll(String token) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar proveedores');
  }

  Future<dynamic> create(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al crear proveedor: ${response.body}');
  }

  Future<dynamic> update(String token, int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al actualizar proveedor: ${response.body}');
  }

  Future<void> delete(String token, int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar proveedor: ${response.body}');
    }
  }
}
