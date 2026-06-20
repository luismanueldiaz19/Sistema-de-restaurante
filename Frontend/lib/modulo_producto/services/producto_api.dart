import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_services.dart';
import '../../utils/constants.dart';
import '../models/producto.dart';

class ProductoApi {
  final ApiService api = ApiService();
  final String baseUrl = "$hostName/api/productos";

  Future<List<Producto>> fetchProductos(String token) async {
    final response = await api.get(baseUrl, token: token);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Producto.fromJson(e)).toList();
    }
    return [];
  }

  Future<Producto> createProducto(Map<String, dynamic> data, String token) async {
    final response = await api.post(baseUrl, data, token: token);
    if (response.statusCode == 201 || response.statusCode == 200) {
      final value = jsonDecode(response.body);
      return Producto.fromJson(value['data']);
    }
    throw Exception("Error al crear producto: ${response.body}");
  }

  Future<Producto> updateProducto(String id, Map<String, dynamic> data, String token) async {
    final response = await api.put("$baseUrl/$id", data, token: token);
    if (response.statusCode == 200) {
      final value = jsonDecode(response.body);
      return Producto.fromJson(value['data']);
    }
    throw Exception("Error al actualizar producto: ${response.body}");
  }

  Future<bool> deleteProducto(int id, String token) async {
    final response = await api.delete("$baseUrl/$id", token: token);
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<String> importProductos(List<int> bytes, String filename, String token) async {
    final uri = Uri.parse("$baseUrl/import");
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      })
      ..files.add(
        http.MultipartFile.fromBytes('documento', bytes, filename: filename),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final value = jsonDecode(response.body);
      return value['message'] ?? "Importado correctamente";
    }
    throw Exception("Error al importar: ${response.body}");
  }
}
