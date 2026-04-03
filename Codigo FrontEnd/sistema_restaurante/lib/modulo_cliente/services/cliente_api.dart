import 'dart:convert';

import '../../services/api_services.dart';
import '../../utils/constants.dart';
import '../models/cliente.dart';

class ClienteApi {
  final ApiService api = ApiService();

  final String baseUrl = "http://$ipLocal/api/clientes";

  /// 🔥 GET TODOS LOS CLIENTES
  Future<List<Cliente>> fetchClients(String token) async {
    final response = await api.get(baseUrl, token: token);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      print("DATA LENGTH: ${data.length}");

      return data
          .map((e) {
            try {
              return Cliente.fromJson(e);
            } catch (error) {
              print("ERROR PARSEANDO: $e");
              print(error);
              return null;
            }
          })
          .where((e) => e != null)
          .cast<Cliente>()
          .toList();
    } else {
      throw Exception("Error al obtener clientes");
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
