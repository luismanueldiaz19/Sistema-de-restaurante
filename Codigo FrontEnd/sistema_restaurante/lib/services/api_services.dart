import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class ApiService {
  /// POST genérico
  Future<http.Response> post(String url, dynamic body, {String? token}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 2));

      debugPrint('POST [$url]: ${response.body}');
      return response;
    } on TimeoutException {
      throw TimeoutException("El servidor tardó demasiado en responder");
    } catch (e) {
      throw Exception("Error en la petición: $e");
    }
  }
}
