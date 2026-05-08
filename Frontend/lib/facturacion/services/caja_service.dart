import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/caja_model.dart';
import '../../utils/constants.dart';

class CajaService {
  final String _baseUrl = '$hostName/api/caja';

  Future<CajaSesion?> getEstadoActual(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/caja/estado'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['data'] != null) {
        return CajaSesion.fromJson(body['data']);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> abrirCaja({
    required String token,
    required int cajaId,
    required int turnoId,
    required double montoInicial,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/caja/abrir'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'caja_id': cajaId,
        'turno_id': turnoId,
        'monto_inicial': montoInicial,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> cerrarCaja({
    required String token,
    required double montoFisico,
    String? comentario,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/caja/cerrar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'monto_final_fisico': montoFisico,
        'comentario': comentario,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<List<Caja>> getCajas(String token) async {
    // Provisionalmente retornamos una lista estática para pruebas
    // En producción esto vendría de un endpoint GET /cajas
    return [
      Caja(id: 1, nombre: 'Caja Principal'),
      Caja(id: 2, nombre: 'Caja Secundaria'),
    ];
  }

  Future<List<Turno>> getTurnos(String token) async {
    return [
      Turno(id: 1, nombre: 'Mañana (08:00 - 16:00)'),
      Turno(id: 2, nombre: 'Tarde (16:00 - 00:00)'),
    ];
  }
}
