import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class CxpApi {
  final String baseUrl = "$hostName/api/cxp";

  Future<List<dynamic>> getAll(String token) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar cuentas por pagar');
  }

  Future<dynamic> registrarPago(String token, int id, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/$id/pagar"),
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
    throw Exception('Error al registrar pago: ${response.body}');
  }
}
