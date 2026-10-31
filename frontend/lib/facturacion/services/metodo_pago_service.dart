import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/constants.dart';
import '../models/metodo_pago.dart';

class MetodoPagoService {
  final String _baseUrl = hostName;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<MetodoPago>> getMetodosPagoActivos() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/metodos-pagos/activos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => MetodoPago.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar métodos de pago');
    }
  }

  Future<List<MetodoPago>> getTodosMetodosPago() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/metodos-pagos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => MetodoPago.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar todos los métodos de pago');
    }
  }

  Future<MetodoPago> createMetodoPago(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/metodos-pagos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return MetodoPago.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear método de pago: ${response.body}');
    }
  }

  Future<MetodoPago> updateMetodoPago(int id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/api/metodos-pagos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return MetodoPago.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar método de pago: ${response.body}');
    }
  }

  Future<void> deleteMetodoPago(int id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/metodos-pagos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar método de pago: ${response.body}');
    }
  }
}
