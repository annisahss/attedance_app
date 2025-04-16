import 'dart:convert';
import 'package:attedance_app/models/login_model.dart';
import 'package:attedance_app/models/register_model.dart';
import 'package:attedance_app/services/endpoint.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<LoginResponse> login(String email, String password) async {
    final url = Uri.parse('${Endpoint.baseUrl}${Endpoint.login}');
    final response = await http.post(
      url,
      body: {'email': email, 'password': password},
    );

    final jsonData = json.decode(response.body);
    if (response.statusCode == 200 && jsonData['success']) {
      final token = jsonData['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    }

    return LoginResponse.fromJson(jsonData);
  }

  Future<RegisterResponse> register(
    String name,
    String email,
    String password,
  ) async {
    final url = Uri.parse('${Endpoint.baseUrl}${Endpoint.register}');
    final response = await http.post(
      url,
      body: {'name': name, 'email': email, 'password': password},
    );

    final jsonData = json.decode(response.body);
    return RegisterResponse.fromJson(jsonData);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
