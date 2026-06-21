import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final loginUrl = Uri.parse('http://localhost:8000/api/login');
  final loginRes = await http.post(
    loginUrl,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': 'lwader@gmail.com', 'password': 'password'}),
  );

  if (loginRes.statusCode != 200) {
    print('Login failed: \${loginRes.body}');
    return;
  }

  final token = jsonDecode(loginRes.body)['data']['token'];
  print('Logged in, token: \$token');

  final asientosUrl = Uri.parse('http://localhost:8000/api/asientos');
  final asientosRes = await http.get(
    asientosUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer \$token',
    },
  );

  print('Status Code: \${asientosRes.statusCode}');
  print('Body: \${asientosRes.body}');
}
