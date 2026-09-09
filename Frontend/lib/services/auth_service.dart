import 'dart:convert';

import '../model/user.dart';
import '../utils/constants.dart';
import 'api_services.dart';

class AuthService {
  final ApiService api = ApiService();

  final String baseUrl = "$hostName/api"; // emulador

  /// LOGIN
  Future<AuthResponse?> login({
    required String email,
    required String password,
  }) async {
    final url = "$baseUrl/login";

    try {
      final response = await api.post(url, {
        "email": email,
        "password": password,
      }, checkUnauthorized: false);

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['status'] == true) {
        return AuthResponse.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print("AUTH_SERVICE: Error login catch: $e");
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
