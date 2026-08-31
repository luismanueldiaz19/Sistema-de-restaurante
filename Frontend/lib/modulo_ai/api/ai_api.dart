import 'dart:convert';
import '../../utils/constants.dart';
import '../../services/api_services.dart';

class AiApi {
  final String baseUrl = "$hostName/api/ai";
  final ApiService api = ApiService();

  Future<String> sendMessage(String token, String message) async {
    final response = await api.post(
      "$baseUrl/chat",
      {"message": message},
      token: token,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['response'];
      }
      throw Exception('Error del agente: ${data['response']}');
    } else {
      throw Exception('Error al comunicarse con la IA: ${response.body}');
    }
  }
}
