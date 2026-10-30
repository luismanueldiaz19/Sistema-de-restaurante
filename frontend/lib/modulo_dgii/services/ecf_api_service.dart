import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_services.dart';
import '../../utils/constants.dart';

class EcfApiService {
  final ApiService _api = ApiService();
  final String _baseUrl = '$apiUrl/ecf';

  Map<String, dynamic> _decodeJson(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      return {'status': false, 'message': 'Respuesta inválida del servidor.'};
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

  Future<Map<String, dynamic>> getEstadoSistema(String token) async {
    final res = await _api.get('$_baseUrl/estado-sistema', token: token);
    final body = _decodeJson(res);
    if (res.statusCode == 200 && body['status'] == true) {
      return {'success': true, ...body};
    }
    return {
      'success': false,
      'message': _extractError(body, 'No se pudo cargar el estado e-CF.'),
    };
  }

  Future<Map<String, dynamic>> actualizarConfiguracion(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final res = await _api.put(
      '$_baseUrl/configuracion',
      payload,
      token: token,
    );
    final body = _decodeJson(res);
    if (res.statusCode == 200 && body['status'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Configuración actualizada.',
        'configuracion': body['configuracion'],
      };
    }
    return {
      'success': false,
      'message': _extractError(body, 'Error al guardar configuración.'),
    };
  }

  Future<Map<String, dynamic>> generarCertificadoPrueba(
    String token, {
    String password = '1234',
  }) async {
    final res = await _api.post('$_baseUrl/certificado/generar-prueba', {
      'password': password,
    }, token: token);
    final body = _decodeJson(res);
    if (res.statusCode == 200 && body['status'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Certificado de prueba generado.',
        'certificado': body['certificado'],
      };
    }
    return {
      'success': false,
      'message': _extractError(body, 'Error al generar certificado .p12.'),
    };
  }

  Future<Map<String, dynamic>> subirCertificadoP12(
    String token, {
    required List<int> fileBytes,
    required String fileName,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/certificado/upload');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['password'] = password
      ..files.add(
        http.MultipartFile.fromBytes(
          'certificado',
          fileBytes,
          filename: fileName,
        ),
      );

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final body = _decodeJson(res);

    if (res.statusCode == 200 && body['status'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Certificado instalado.',
        'certificado': body['certificado'],
      };
    }
    return {
      'success': false,
      'message': _extractError(body, 'Error al instalar certificado .p12.'),
    };
  }

  Future<Map<String, dynamic>> probarConexion(String token) async {
    final res = await _api.post('$_baseUrl/probar-conexion', {}, token: token);
    final body = _decodeJson(res);
    if (res.statusCode == 200 && body['status'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Conexión exitosa.',
        'data': body['data'],
      };
    }
    return {
      'success': false,
      'message': _extractError(body, 'Fallo en autenticación DGII.'),
    };
  }

  Future<Map<String, dynamic>> getDocumentos(
    String token, {
    int page = 1,
    String? estado,
    String? tipoEcf,
    String? search,
  }) async {
    final params = <String, String>{'page': page.toString(), 'per_page': '20'};
    if (estado != null && estado.isNotEmpty) params['estado'] = estado;
    if (tipoEcf != null && tipoEcf.isNotEmpty) params['tipo_ecf'] = tipoEcf;
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    final query = Uri(queryParameters: params).query;
    final res = await _api.get('$_baseUrl/documentos?$query', token: token);
    final body = _decodeJson(res);
    if (res.statusCode == 200 && body['status'] == true) {
      return {'success': true, 'data': body['data']};
    }
    return {
      'success': false,
      'message': _extractError(body, 'Error al listar comprobantes e-CF.'),
    };
  }

  Future<Map<String, dynamic>> getDocumentoDetalle(String token, int id) async {
    final res = await _api.get('$_baseUrl/documentos/$id', token: token);
    final body = _decodeJson(res);
    if (res.statusCode == 200 && body['status'] == true) {
      return {'success': true, ...body};
    }
    return {
      'success': false,
      'message': _extractError(body, 'No se pudo cargar el XML del e-CF.'),
    };
  }

  Future<Map<String, dynamic>> reenviarDocumento(String token, int id) async {
    final res = await _api.post(
      '$_baseUrl/documentos/$id/reenviar',
      {},
      token: token,
    );
    final body = _decodeJson(res);
    if (res.statusCode == 200 && body['status'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Comprobante reenviado.',
        'documento': body['documento'],
      };
    }
    return {
      'success': false,
      'message': _extractError(body, 'Error al reenviar comprobante.'),
    };
  }

  Future<Map<String, dynamic>> consultarEstadoDocumento(
    String token,
    int id,
  ) async {
    final res = await _api.get(
      '$_baseUrl/documentos/$id/consultar-estado',
      token: token,
    );
    final body = _decodeJson(res);
    if (res.statusCode == 200 && body['status'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Estado actualizado.',
        'documento': body['documento'],
      };
    }
    return {
      'success': false,
      'message': _extractError(body, 'Error al consultar TrackId.'),
    };
  }
}
