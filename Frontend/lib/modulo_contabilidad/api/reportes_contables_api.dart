import 'dart:convert';
import '../../utils/constants.dart';
import '../../services/api_services.dart';

class ReportesContablesApi {
  final String baseUrl = "$hostName/api/contabilidad";

  Future<List<dynamic>> getMayorGeneral(String token, {String? fechaDesde, String? fechaHasta}) async {
    final api = ApiService();
    String url = "$baseUrl/mayor-general?";
    if (fechaDesde != null) url += "fecha_desde=$fechaDesde&";
    if (fechaHasta != null) url += "fecha_hasta=$fechaHasta";

    final response = await api.get(url, token: token);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    throw Exception('Error al cargar Mayor General');
  }

  Future<Map<String, dynamic>> getBalanceGeneral(String token, {String? fechaHasta}) async {
    final api = ApiService();
    String url = "$baseUrl/balance-general?";
    if (fechaHasta != null) url += "fecha_hasta=$fechaHasta";

    final response = await api.get(url, token: token);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    throw Exception('Error al cargar Balance General');
  }

  Future<Map<String, dynamic>> getEstadoResultados(String token, {String? fechaDesde, String? fechaHasta}) async {
    final api = ApiService();
    String url = "$baseUrl/estado-resultados?";
    if (fechaDesde != null) url += "fecha_desde=$fechaDesde&";
    if (fechaHasta != null) url += "fecha_hasta=$fechaHasta";

    final response = await api.get(url, token: token);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    throw Exception('Error al cargar Estado de Resultados');
  }
}
