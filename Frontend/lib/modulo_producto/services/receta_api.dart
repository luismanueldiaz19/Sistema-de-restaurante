import 'dart:convert';
import '../../services/api_services.dart';
import '../../utils/constants.dart';
import '../models/producto.dart';

class RecetaApi {
  final ApiService api = ApiService();
  final String baseUrl = "$hostName/api/recetas";

  Future<List<Producto>> fetchProductosConRecetas(String token) async {
    final response = await api.get(baseUrl, token: token);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => Producto.fromJson(e)).toList();
    }
    return [];
  }

  Future<Producto> updateReceta(String productoId, List<Map<String, dynamic>> ingredientes, String token) async {
    final response = await api.put(
      "$baseUrl/$productoId",
      {'ingredientes': ingredientes},
      token: token,
    );
    if (response.statusCode == 200) {
      final value = jsonDecode(response.body);
      return Producto.fromJson(value['data']);
    }
    throw Exception("Error al actualizar receta: ${response.body}");
  }
}
