import 'dart:convert';
import '../../services/api_services.dart';
import '../../utils/constants.dart';
import '../models/movimiento_inventario.dart';

class InventarioApi {
  final ApiService api = ApiService();
  final String baseUrl = "$hostName/api/inventario";

  Future<List<MovimientoInventario>> fetchMovimientos(String token) async {
    final response = await api.get("$baseUrl/movimientos", token: token);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => MovimientoInventario.fromJson(e)).toList();
    }
    throw Exception("Error al cargar movimientos: ${response.body}");
  }

  Future<MovimientoInventario> registrarAjuste(
    int productoId,
    String tipo,
    double cantidad,
    String motivo,
    String token,
  ) async {
    final response = await api.post(
      "$baseUrl/ajuste",
      {
        'producto_id': productoId,
        'tipo': tipo,
        'cantidad': cantidad,
        'motivo': motivo,
      },
      token: token,
    );

    if (response.statusCode == 201) {
      final value = jsonDecode(response.body);
      return MovimientoInventario.fromJson(value['data']);
    }
    throw Exception("Error al registrar ajuste: ${response.body}");
  }
}
