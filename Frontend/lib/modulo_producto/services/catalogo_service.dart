import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class CatalogoService {
  final String endpoint;

  CatalogoService(this.endpoint);

  Future<List<dynamic>> getAll(String token) async {
    final response = await http.get(
      Uri.parse('$hostName/api/$endpoint'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? [];
    }
    throw Exception('Error al cargar $endpoint');
  }

  Future<dynamic> create(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$hostName/api/$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return decoded['data'];
    }
    throw Exception('Error al crear en $endpoint');
  }

  Future<dynamic> update(
    String token,
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$hostName/api/$endpoint/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'];
    }
    throw Exception('Error al actualizar en $endpoint');
  }

  Future<void> delete(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$hostName/api/$endpoint/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar en $endpoint');
    }
  }
}
