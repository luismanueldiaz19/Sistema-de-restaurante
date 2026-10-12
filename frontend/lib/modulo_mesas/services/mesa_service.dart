import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_services.dart';
import '../../utils/constants.dart';
import '../models/mesa_model.dart';

class MesaService {
  final ApiService api = ApiService();
  final String baseUrl = "$apiUrl/mesas";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Obtiene la lista de mesas y áreas
  Future<Map<String, dynamic>> getMesas({String? area}) async {
    final token = await _getToken();
    final url = (area != null && area != 'Todas') ? '$baseUrl?area=$area' : baseUrl;
    final response = await api.get(url, token: token);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List list = decoded['data'] ?? [];
      final List<String> areas = (decoded['areas'] as List? ?? ['Principal'])
          .map((e) => e.toString())
          .toList();

      final mesas = list.map((e) => MesaModel.fromJson(e)).toList();
      return {
        'mesas': mesas,
        'areas': areas,
      };
    }
    throw Exception('Error al cargar mesas: ${response.body}');
  }

  /// Crear nueva mesa
  Future<MesaModel> crearMesa(Map<String, dynamic> payload) async {
    final token = await _getToken();
    final response = await api.post(baseUrl, payload, token: token);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return MesaModel.fromJson(decoded['data']);
    }
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Error al crear mesa');
  }

  /// Actualizar mesa (nombre, área, capacidad)
  Future<MesaModel> actualizarMesa(int id, Map<String, dynamic> payload) async {
    final token = await _getToken();
    final response = await api.put('$baseUrl/$id', payload, token: token);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return MesaModel.fromJson(decoded['data']);
    }
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Error al actualizar mesa');
  }

  /// Eliminar mesa
  Future<bool> eliminarMesa(int id) async {
    final token = await _getToken();
    final response = await api.delete('$baseUrl/$id', token: token);

    if (response.statusCode == 200) {
      return true;
    }
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Error al eliminar mesa');
  }

  /// Abrir mesa con pedido inicial
  Future<MesaModel> abrirMesa(int id, Map<String, dynamic> payload) async {
    final token = await _getToken();
    final response = await api.post('$baseUrl/$id/abrir', payload, token: token);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return MesaModel.fromJson(decoded['data']);
    }
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Error al abrir mesa');
  }

  /// Agregar platos/bebidas a una mesa abierta
  Future<MesaModel> agregarItems(int id, Map<String, dynamic> payload) async {
    final token = await _getToken();
    final response = await api.post('$baseUrl/$id/agregar-items', payload, token: token);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return MesaModel.fromJson(decoded['data']);
    }
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Error al agregar ítems a la mesa');
  }

  /// Solicitar cuenta / Pre-cuenta
  Future<MesaModel> solicitarCuenta(int id) async {
    final token = await _getToken();
    final response = await api.post('$baseUrl/$id/solicitar-cuenta', {}, token: token);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return MesaModel.fromJson(decoded['data']);
    }
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Error al solicitar cuenta');
  }

  /// Liberar mesa manualmente (admin) o por facturación (cajero)
  Future<MesaModel> liberarMesa(int id, {bool porFactura = false}) async {
    final token = await _getToken();
    final response = await api.post(
      '$baseUrl/$id/liberar',
      {'por_factura': porFactura},
      token: token,
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return MesaModel.fromJson(decoded['data']);
    }
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Error al liberar mesa');
  }
}
