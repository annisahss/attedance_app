import 'dart:convert';
import 'package:attedance_app/models/login_model.dart';
import 'package:attedance_app/models/register_model.dart';
import 'package:attedance_app/services/endpoint.dart';
import 'package:attedance_app/services/shared_pref_service.dart';
import 'package:http/http.dart' as http;

class AuthService {
  /// LOGIN
  Future<LoginResponse> login(String email, String password) async {
    final url = Uri.parse('${Endpoint.baseUrl}${Endpoint.login}');
    final response = await http.post(
      url,
      body: {'email': email, 'password': password},
      headers: {'Accept': 'application/json'},
    );

    final jsonData = json.decode(response.body);

    if (response.statusCode == 200 && jsonData['data'] != null) {
      final token = jsonData['data']['token'];
      final user = jsonData['data']['user'];

      await SharedPrefService.saveToken(token);
      await SharedPrefService.saveUserInfo(
        name: user['name'],
        email: user['email'],
      );
    }

    return LoginResponse.fromJson(jsonData);
  }

  /// REGISTER
  Future<RegisterResponse> register(
    String name,
    String email,
    String password,
  ) async {
    final url = Uri.parse('${Endpoint.baseUrl}${Endpoint.register}');
    final response = await http.post(
      url,
      body: {'name': name, 'email': email, 'password': password},
      headers: {'Accept': 'application/json'},
    );

    final jsonData = json.decode(response.body);
    final result = RegisterResponse.fromJson(jsonData);

    // Optional: log error detail jika validasi gagal
    if (response.statusCode != 200) {
      print('📛 Register failed: ${result.errors?.toJson()}');
    }

    return result;
  }

  /// LOGOUT
  Future<void> logout() async {
    await SharedPrefService.clearAll();
  }
}
