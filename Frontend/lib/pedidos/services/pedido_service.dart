import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_services.dart';
import '../../utils/constants.dart';
import '../models/pedido.dart';

class PedidoService {
  final ApiService api = ApiService();
  final String baseUrl = "$apiUrl/pedidos";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<Pedido>> getPedidos(String fecha) async {
    final token = await _getToken();
    final response = await api.get('$baseUrl?fecha=$fecha', token: token);

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
    final response = await api.get('$baseUrl/codigo/$codigo', token: token);

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
    final response = await api.put('$baseUrl/$id/estado', {
      'estado': estado,
    }, token: token);

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

    final response = await api.post(baseUrl, payload, token: token);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return {'success': true, 'data': data['pedido'] ?? data};
    } else {
      try {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error al crear pedido',
        };
      } catch (_) {
        return {
          'success': false,
          'message': 'Error al crear pedido (${response.statusCode})',
        };
      }
    }
  }
}
