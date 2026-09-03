import 'dart:convert';

import '../../services/api_services.dart';
import '../../utils/constants.dart';
import '../models/cliente.dart';

class ClienteApi {
  final ApiService api = ApiService();

  final String baseUrl = "$hostName/api/clientes";

  /// 🔥 GET TODOS LOS CLIENTES (Paginated)
  Future<Map<String, dynamic>> fetchClients(
    String token, {
    int page = 1,
    String search = '',
  }) async {
    final queryUrl = "$baseUrl?page=$page&search=$search";
    final response = await api.get(queryUrl, token: token);

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List data = body['data'] ?? [];

      // print("DATA LENGTH: ${data.length}");

      final clientes = data
          .map((e) {
            try {
              return Cliente.fromJson(e);
            } catch (error) {
              return null;
            }
          })
          .where((e) => e != null)
          .cast<Cliente>()
          .toList();

      return {
        'clientes': clientes,
        'current_page': body['current_page'] ?? 1,
        'last_page': body['last_page'] ?? 1,
      };
    } else {
      return {'clientes': <Cliente>[], 'current_page': 1, 'last_page': 1};
    }
  }

  /// 🔥 GET CLIENTE POR ID
  Future<Cliente> getClientById(String id, String token) async {
    final response = await api.get("$baseUrl/$id", token: token);

    if (response.statusCode == 200) {
      return Cliente.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Cliente no encontrado");
    }
  }

  /// 🔥 CREAR CLIENTE (POST)
  Future<Cliente> createClient(Map<String, dynamic> data, String token) async {
    final response = await api.post(baseUrl, data, token: token);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final res = response.body;
      final value = jsonDecode(res);

      return Cliente.fromJson(value['data']);
    } else {
      throw Exception("Error al crear cliente");
    }
  }

  /// 🔥 ACTUALIZAR CLIENTE (PUT)
  Future<Cliente> updateClient(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await api.put("$baseUrl/$id", data, token: token);

    if (response.statusCode == 200) {
      final res = response.body;
      final value = jsonDecode(res);

      return Cliente.fromJson(value['data']);
    } else {
      throw Exception("Error al actualizar cliente");
    }
  }

  /// 🔥 ELIMINAR CLIENTE (DELETE)
  Future<bool> deleteClient(int id, String token) async {
    final response = await api.delete("$baseUrl/$id", token: token);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception("Error al eliminar cliente");
    }
  }
}
