import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://absen.quidi.id/';

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final json = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': json['data'],
        'message': json['message'],
      };
    } else {
      return {
        'success': false,
        'message': json['message'],
        'errors': json['errors'],
      };
    }
  }
}
