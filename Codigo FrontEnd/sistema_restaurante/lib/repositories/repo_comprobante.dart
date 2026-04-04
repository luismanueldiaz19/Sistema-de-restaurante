import 'dart:convert';

import 'package:sistema_restaurante/model/comprobante.dart';

import '../services/api_services.dart';

class ComprobanteRepository {
  final ApiService api = ApiService();

  final String baseUrl = "http://127.0.0.1:8000/api/ncf-secuencias";

  Future<List<Comprobante>> getComprabante(String token) async {
    final response = await api.get(baseUrl, token: token);

    if (response.statusCode == 200) {
      final value = jsonDecode(response.body);
      final List data = value['data'];

      print("DATA LENGTH: ${data.length}");

      return data
          .map((e) {
            try {
              return Comprobante.fromJson(e);
            } catch (error) {
              print("ERROR PARSEANDO: $e");
              print(error);
              return null;
            }
          })
          .where((e) => e != null)
          .cast<Comprobante>()
          .toList();
    } else {
      throw Exception("Error al obtener clientes");
    }
  }
}
