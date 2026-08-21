import 'dart:convert';
import '../../utils/constants.dart';
import '../../services/api_services.dart';
import '../models/cxc.dart';
import '../models/pago_cxc.dart';

class CxcApi {
  final String baseUrl = "$hostName/api/cxc";
  final ApiService api = ApiService();

  Future<List<CuentaPorCobrar>> getCxcs(String token) async {
    final response = await api.get(baseUrl, token: token);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => CuentaPorCobrar.fromJson(json)).toList();
    } else {
      throw Exception(
        'Error al cargar las Cuentas por Cobrar: ${response.body}',
      );
    }
  }

  Future<bool> registrarPago(
    String token,
    int cxcId,
    Map<String, dynamic> pagoData,
  ) async {
    final response = await api.post(
      "$baseUrl/$cxcId/pagar",
      pagoData,
      token: token,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Error al registrar cobro: ${response.body}');
    }
  }

  Future<List<PagoCxc>> getHistorialPagos(String token) async {
    final response = await api.get("$baseUrl/pagos/historial", token: token);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => PagoCxc.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar historial de pagos: ${response.body}');
    }
  }
}
