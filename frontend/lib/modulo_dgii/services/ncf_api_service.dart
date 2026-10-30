import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_services.dart';
import '../../utils/constants.dart';

class NcfApiService {
  final ApiService _api = ApiService();
  final String _baseUrl = '$hostName/api/ncf-secuencias';

  Map<String, dynamic> _decode(http.Response res) {
    try {
      final d = jsonDecode(res.body);
      if (d is Map<String, dynamic>) return d;
      return {'data': d};
    } catch (_) {
      return {'message': 'Respuesta inválida del servidor.'};
    }
  }

  String _extractError(Map<String, dynamic> body, String fallback) {
    if (body['errors'] is Map) {
      final errors = body['errors'] as Map;
      if (errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }
    return (body['message'] ?? body['error'] ?? fallback).toString();
  }

  Future<Map<String, dynamic>> listarTodas(String token) async {
    final res = await _api.get('$_baseUrl?all=1', token: token);
    final body = _decode(res);
    if (res.statusCode == 200) {
      return {'success': true, 'data': body['data'] ?? []};
    }
    return {
      'success': false,
      'message': _extractError(body, 'No se pudieron cargar las secuencias.'),
    };
  }

  Future<Map<String, dynamic>> crear(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final res = await _api.post(_baseUrl, payload, token: token);
    final body = _decode(res);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return {
        'success': true,
        'message': body['message'] ?? 'Secuencia creada.',
      };
    }
    return {
      'success': false,
      'message': _extractError(body, 'Error al crear secuencia NCF.'),
    };
  }

  Future<Map<String, dynamic>> actualizar(
    String token,
    int id,
    Map<String, dynamic> payload,
  ) async {
    final res = await _api.put('$_baseUrl/$id', payload, token: token);
    final body = _decode(res);
    if (res.statusCode == 200) {
      return {
        'success': true,
        'message': body['message'] ?? 'Secuencia actualizada.',
      };
    }
    return {
      'success': false,
      'message': _extractError(body, 'Error al actualizar secuencia NCF.'),
    };
  }

  Future<Map<String, dynamic>> toggleActivo(String token, int id) async {
    final res = await _api.patch('$_baseUrl/$id/toggle', {}, token: token);
    final body = _decode(res);
    if (res.statusCode == 200) {
      return {
        'success': true,
        'message': body['message'] ?? 'Estado actualizado.',
      };
    }
    return {
      'success': false,
      'message': _extractError(body, 'No se pudo cambiar el estado.'),
    };
  }
}

