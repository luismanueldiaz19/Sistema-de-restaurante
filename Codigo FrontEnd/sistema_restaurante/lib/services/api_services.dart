import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

const int seconds = 50;

class ApiService {
  static VoidCallback? onUnauthorized; // 👈 GLOBAL

  Map<String, String> _headers(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      // 🔥 TOKEN EXPIRADO
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
    }
  }

  /// GET
  Future<http.Response> get(String url, {String? token}) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers(token))
          .timeout(const Duration(seconds: seconds));
      debugPrint('GET [$url]: ${response.body}');
      _handleResponse(response); // 🔥 TOKEN EXPIRADO

      return response;
    } on TimeoutException {
      throw TimeoutException("El servidor tardó demasiado en responder");
    } catch (e) {
      throw Exception("Error en GET: $e");
    }
  }

  /// POST
  Future<http.Response> post(String url, dynamic body, {String? token}) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: seconds));

      debugPrint('POST [$url]: ${response.body}');
      _handleResponse(response); // 🔥 TOKEN EXPIRADO
      return response;
    } on TimeoutException {
      throw TimeoutException("El servidor tardó demasiado en responder");
    } catch (e) {
      throw Exception("Error en POST: $e");
    }
  }

  /// PUT (actualización completa)
  Future<http.Response> put(String url, dynamic body, {String? token}) async {
    try {
      final response = await http
          .put(Uri.parse(url), headers: _headers(token), body: jsonEncode(body))
          .timeout(const Duration(seconds: seconds));

      debugPrint('PUT [$url]: ${response.body}');
      _handleResponse(response); // 🔥 TOKEN EXPIRADO
      return response;
    } on TimeoutException {
      throw TimeoutException("El servidor tardó demasiado en responder");
    } catch (e) {
      throw Exception("Error en PUT: $e");
    }
  }

  /// PATCH (actualización parcial)
  Future<http.Response> patch(String url, dynamic body, {String? token}) async {
    try {
      final response = await http
          .patch(
            Uri.parse(url),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: seconds));

      debugPrint('PATCH [$url]: ${response.body}');
      _handleResponse(response); // 🔥 TOKEN EXPIRADO
      return response;
    } on TimeoutException {
      throw TimeoutException("El servidor tardó demasiado en responder");
    } catch (e) {
      throw Exception("Error en PATCH: $e");
    }
  }

  /// DELETE
  Future<http.Response> delete(String url, {String? token}) async {
    try {
      final response = await http
          .delete(Uri.parse(url), headers: _headers(token))
          .timeout(const Duration(seconds: seconds));

      debugPrint('DELETE [$url]: ${response.body}');
      _handleResponse(response); // 🔥 TOKEN EXPIRADO
      return response;
    } on TimeoutException {
      throw TimeoutException("El servidor tardó demasiado en responder");
    } catch (e) {
      throw Exception("Error en DELETE: $e");
    }
  }
}
