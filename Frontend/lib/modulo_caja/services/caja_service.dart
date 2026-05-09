import 'dart:convert';
import 'package:sistema_restaurante/services/api_services.dart';
import '../../utils/constants.dart';

class CajaService {
  final ApiService _api = ApiService();
  final String _baseUrl = "$hostName/api/caja";

  Future<Map<String, dynamic>> getEstadoCaja(String token) async {
    try {
      final response = await _api.get("$_baseUrl/estado", token: token);
      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data['data']};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getResumenCierre(String token) async {
    try {
      final response = await _api.get("$_baseUrl/resumen", token: token);
      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data['data']};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> cerrarCaja({
    required String token,
    required double montoFisico,
    required Map<String, int> desglose,
    String? comentario,
  }) async {
    try {
      final response = await _api.post(
        "$_baseUrl/cerrar",
        {
          "monto_final_fisico": montoFisico,
          "desglose": desglose,
          "comentario": comentario,
        },
        token: token,
      );
      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "message": data['message']};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> abrirCaja({
    required String token,
    required int cajaId,
    required int turnoId,
    required double montoInicial,
  }) async {
    try {
      final response = await _api.post(
        "$_baseUrl/abrir",
        {
          "caja_id": cajaId,
          "turno_id": turnoId,
          "monto_inicial": montoInicial,
        },
        token: token,
      );
      final data = jsonDecode(response.body);
      return {
        "success": response.statusCode == 200 || response.statusCode == 201,
        "data": data['data'],
        "message": data['message']
      };
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<List<dynamic>> getCajas(String token) async {
    try {
      final response = await _api.get("$hostName/api/cajas", token: token);
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getTurnos(String token) async {
    try {
      final response = await _api.get("$hostName/api/turnos", token: token);
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getHistorial({
    required String token,
    Map<String, String>? filters,
  }) async {
    try {
      String query = '';
      if (filters != null && filters.isNotEmpty) {
        query = '?' + filters.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await _api.get("$_baseUrl/historial$query", token: token);
      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data['data']};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
