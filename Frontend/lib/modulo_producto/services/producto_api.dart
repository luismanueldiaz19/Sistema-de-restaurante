import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../services/api_services.dart';
import '../../utils/constants.dart';
import '../models/producto.dart';

class ProductoApi {
  final ApiService api = ApiService();
  final String baseUrl = "$apiUrl/productos";

  Future<Map<String, dynamic>> fetchProductos(
    String token, {
    int page = 1,
    int perPage = 500,
    String search = '',
    int? categoriaId,
    int? marcaId,
    String? tipoProducto,
  }) async {
    String queryParams =
        "?page=$page&per_page=$perPage&search=${Uri.encodeComponent(search)}";
    if (categoriaId != null) queryParams += "&categoria_id=$categoriaId";
    if (marcaId != null) queryParams += "&marca_id=$marcaId";
    if (tipoProducto != null && tipoProducto.isNotEmpty) {
      queryParams += "&tipo_producto=$tipoProducto";
    }

    final response = await api.get("$baseUrl$queryParams", token: token);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData.containsKey('data')) {
        var dataField = responseData['data'];
        List dataList = [];
        int current = 1;
        int last = 1;
        int total = 0;

        if (dataField is Map && dataField.containsKey('data')) {
          dataList = dataField['data'] is List ? dataField['data'] : [];
          var meta = dataField['meta'];
          if (meta is Map) {
            current =
                int.tryParse(meta['current_page']?.toString() ?? '1') ?? 1;
            last = int.tryParse(meta['last_page']?.toString() ?? '1') ?? 1;
            total =
                int.tryParse(meta['total']?.toString() ?? '0') ??
                dataList.length;
          } else {
            total = dataList.length;
          }
        } else if (dataField is List) {
          dataList = dataField;
          current =
              int.tryParse(responseData['current_page']?.toString() ?? '1') ??
              1;
          last =
              int.tryParse(responseData['last_page']?.toString() ?? '1') ?? 1;
          total =
              int.tryParse(responseData['total']?.toString() ?? '0') ??
              dataList.length;
        }

        final productos = dataList.map((e) => Producto.fromJson(e)).toList();
        return {
          'productos': productos,
          'currentPage': current,
          'totalPages': last,
          'totalRecords': total,
        };
      }
    }

    return {
      'productos': <Producto>[],
      'currentPage': 1,
      'totalPages': 1,
      'totalRecords': 0,
    };
  }

  Future<Map<String, dynamic>> fetchProductosCompras(
    String token, {
    int page = 1,
    int perPage = 500,
    String search = '',
    int? categoriaId,
    int? marcaId,
  }) async {
    String queryParams =
        "?page=$page&per_page=$perPage&search=${Uri.encodeComponent(search)}";
    if (categoriaId != null) queryParams += "&categoria_id=$categoriaId";
    if (marcaId != null) queryParams += "&marca_id=$marcaId";

    final response = await api.get(
      "$apiUrl/productos-compras$queryParams",
      token: token,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData.containsKey('data')) {
        var dataField = responseData['data'];
        List dataList = [];
        int current = 1;
        int last = 1;
        int total = 0;

        if (dataField is Map && dataField.containsKey('data')) {
          dataList = dataField['data'] is List ? dataField['data'] : [];
          var meta = dataField['meta'];
          if (meta is Map) {
            current =
                int.tryParse(meta['current_page']?.toString() ?? '1') ?? 1;
            last = int.tryParse(meta['last_page']?.toString() ?? '1') ?? 1;
            total =
                int.tryParse(meta['total']?.toString() ?? '0') ??
                dataList.length;
          } else {
            total = dataList.length;
          }
        } else if (dataField is List) {
          dataList = dataField;
          current =
              int.tryParse(responseData['current_page']?.toString() ?? '1') ??
              1;
          last =
              int.tryParse(responseData['last_page']?.toString() ?? '1') ?? 1;
          total =
              int.tryParse(responseData['total']?.toString() ?? '0') ??
              dataList.length;
        }

        final productos = dataList.map((e) => Producto.fromJson(e)).toList();
        return {
          'productos': productos,
          'currentPage': current,
          'totalPages': last,
          'totalRecords': total,
        };
      }
    }

    return {
      'productos': <Producto>[],
      'currentPage': 1,
      'totalPages': 1,
      'totalRecords': 0,
    };
  }

  Future<Producto> createProducto(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await api.post(baseUrl, data, token: token);
    if (response.statusCode == 201 || response.statusCode == 200) {
      final value = jsonDecode(response.body);
      return Producto.fromJson(value['data']);
    }
    String errorMsg = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded['message'] != null) {
        errorMsg = decoded['message'];
      }
    } catch (_) {}
    throw Exception(errorMsg);
  }

  Future<Producto> updateProducto(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await api.put("$baseUrl/$id", data, token: token);
    if (response.statusCode == 200) {
      final value = jsonDecode(response.body);
      return Producto.fromJson(value['data']);
    }
    String errorMsg = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded['message'] != null) {
        errorMsg = decoded['message'];
      }
    } catch (_) {}
    throw Exception(errorMsg);
  }

  Future<bool> deleteProducto(int id, String token) async {
    final response = await api.delete("$baseUrl/$id", token: token);
    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// Descarga los bytes del archivo Excel (.xlsx) de la plantilla base de productos inventariables
  Future<Uint8List> downloadTemplateBytes(String token) async {
    final uri = Uri.parse("$baseUrl/template");
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/json',
      },
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception("Error al descargar plantilla (${response.statusCode})");
  }

  /// Envía el archivo Excel/CSV para validar y previsualizar las filas antes de guardar
  Future<Map<String, dynamic>> previewImportProductos(
    List<int> bytes,
    String filename,
    String token,
  ) async {
    final uri = Uri.parse("$baseUrl/import/preview");
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
    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200 && decoded['success'] == true) {
      return Map<String, dynamic>.from(decoded['data']);
    }

    final msg = decoded['message'] ?? 'Error al procesar el archivo';
    throw Exception(msg);
  }

  /// Confirma la importación masiva enviando las filas revisadas por el usuario
  Future<Map<String, dynamic>> confirmImportProductos(
    List<Map<String, dynamic>> productos,
    String token,
  ) async {
    final response = await api.post(
      "$baseUrl/import/confirm",
      {'productos': productos},
      token: token,
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['success'] == true) {
      return {
        'message': decoded['message'] ?? 'Importación completada',
        'data': decoded['data'] ?? {},
      };
    }

    final msg = decoded['message'] ?? 'Error al confirmar la importación';
    throw Exception(msg);
  }

  Future<String> importProductos(
    List<int> bytes,
    String filename,
    String token,
  ) async {
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
