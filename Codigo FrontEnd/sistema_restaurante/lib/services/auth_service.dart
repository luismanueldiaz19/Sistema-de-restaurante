import 'dart:convert';

import '../model/user.dart';
import 'api_services.dart';

class AuthService {
  final ApiService api = ApiService();

  final String baseUrl = "http://127.0.0.1:8000/api"; // emulador

  /// LOGIN
  Future<AuthResponse?> login({
    required String email,
    required String password,
  }) async {
    final url = "$baseUrl/login";

    try {
      final response = await api.post(
        url,
        jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return AuthResponse.fromJson(data); // 🔥 CLAVE
      } else {
        return null;
      }
    } catch (e) {
      print("Error login: $e");
      return null;
    }
  }

  /// REGISTER (opcional)
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = "$baseUrl/register";

    try {
      final response = await api.post(
        url,
        jsonEncode({"name": name, "email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error en registro',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
