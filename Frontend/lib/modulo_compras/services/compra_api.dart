import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class CompraApi {
  final String baseUrl = "$hostName/api/compras";

  Future<List<dynamic>> getAll(String token) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar compras');
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
    throw Exception('Error al registrar compra: ${response.body}');
  }
}
