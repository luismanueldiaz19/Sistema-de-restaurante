import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/constants.dart';
import '../models/pedido.dart';

class PedidoService {
  final String _baseUrl = hostName;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<Pedido>> getPedidos(String fecha) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/pedidos?fecha=$fecha'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('===== RESPUESTA CREAR PEDIDO =====');
    print('StatusCode: ${response.statusCode}');
    print('Body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final List<dynamic> list = data['data'];
        return list.map((e) => Pedido.fromJson(e)).toList();
      }
    }
    throw Exception('Error al cargar pedidos: ${response.body}');
  }

  Future<Pedido?> getPedidoByCodigo(String codigo) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/pedidos/codigo/$codigo'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['pedido'] != null) {
        return Pedido.fromJson(data['pedido']);
      }
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Error al buscar pedido por código: ${response.body}');
  }

  Future<Pedido> updateStatus(int id, String estado) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/api/pedidos/$id/estado'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'estado': estado}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return Pedido.fromJson(data['pedido']);
      }
    }
    throw Exception('Error al actualizar estado: ${response.body}');
  }

  Future<Map<String, dynamic>> crearPedido(Map<String, dynamic> payload) async {
    final token = await _getToken();
    print('===== CREANDO PEDIDO =====');
    print('Payload: ${json.encode(payload)}');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/pedidos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );

    print('===== RESPUESTA CREAR PEDIDO =====');
    print('StatusCode: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return {'success': true, 'data': data['pedido'] ?? data};
    } else {
      final error = json.decode(response.body);
      return {
        'success': false,
        'message': error['message'] ?? 'Error al crear pedido',
      };
    }
  }
}
