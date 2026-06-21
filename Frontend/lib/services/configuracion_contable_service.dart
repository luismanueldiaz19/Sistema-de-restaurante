import 'dart:convert';
import 'package:sistema_restaurante/model/catalogo_cuenta_model.dart';
import 'package:sistema_restaurante/model/configuracion_contable_model.dart';
import 'package:sistema_restaurante/model/asiento_contable_model.dart';
import 'package:sistema_restaurante/services/api_services.dart';
import 'package:sistema_restaurante/utils/constants.dart';

class ConfiguracionContableService {
  final ApiService _api = ApiService();
  final String _baseUrl = '$hostName/api';

  /// Obtener el catálogo de cuentas con opción de filtrado
  Future<List<CatalogoCuentaModel>> getCatalogoCuentas({
    required String token,
    bool? permiteMovimiento,
  }) async {
    String url = '$_baseUrl/catalogo-cuentas';
    if (permiteMovimiento != null) {
      url += '?permite_movimiento=$permiteMovimiento';
    }

    final response = await _api.get(url, token: token);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] as List<dynamic>;
      return data.map((json) => CatalogoCuentaModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Error al obtener catálogo de cuentas');
    }
  }

  /// Obtener la lista completa de configuraciones contables configuradas
  Future<List<ConfiguracionContableModel>> getConfiguraciones({
    required String token,
  }) async {
    final url = '$_baseUrl/configuracion-contable';
    final response = await _api.get(url, token: token);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] as List<dynamic>;
      return data.map((json) => ConfiguracionContableModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Error al obtener configuraciones contables');
    }
  }

  /// Actualizar una configuración contable individual
  Future<ConfiguracionContableModel> updateConfiguracion({
    required String token,
    required int id,
    required int? cuentaId,
  }) async {
    final url = '$_baseUrl/configuracion-contable/$id';
    final response = await _api.put(
      url,
      {'cuenta_id': cuentaId},
      token: token,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return ConfiguracionContableModel.fromJson(decoded['data'] as Map<String, dynamic>);
    } else {
      final decoded = jsonDecode(response.body);
      throw Exception(decoded['message'] ?? 'Error al actualizar configuración contable');
    }
  }

  /// Actualizar múltiples configuraciones contables en un solo envío
  Future<List<ConfiguracionContableModel>> bulkUpdateConfiguraciones({
    required String token,
    required List<Map<String, dynamic>> configs,
  }) async {
    final url = '$_baseUrl/configuracion-contable/bulk';
    final response = await _api.post(
      url,
      {'configs': configs},
      token: token,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] as List<dynamic>;
      return data.map((json) => ConfiguracionContableModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      final decoded = jsonDecode(response.body);
      throw Exception(decoded['message'] ?? 'Error al guardar configuraciones contables');
    }
  }

  /// Obtener la lista completa de asientos contables del sistema (Libro Diario)
  Future<List<AsientoContableModel>> getAsientosContables({
    required String token,
    String? fechaDesde,
    String? fechaHasta,
    String? buscar,
  }) async {
    String url = '$_baseUrl/asientos';
    List<String> params = [];
    if (fechaDesde != null && fechaDesde.isNotEmpty) {
      params.add('fecha_desde=$fechaDesde');
    }
    if (fechaHasta != null && fechaHasta.isNotEmpty) {
      params.add('fecha_hasta=$fechaHasta');
    }
    if (buscar != null && buscar.isNotEmpty) {
      params.add('buscar=${Uri.encodeComponent(buscar)}');
    }
    if (params.isNotEmpty) {
      url += '?' + params.join('&');
    }

    final response = await _api.get(url, token: token);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data']['data'] as List<dynamic>;
      return data.map((json) => AsientoContableModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      final decoded = jsonDecode(response.body);
      final msg = decoded['message'] ?? 'Error desconocido';
      throw Exception('Error al obtener asientos contables: $msg');
    }
  }
}
