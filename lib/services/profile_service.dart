import 'dart:convert';
import 'package:attedance_app/models/edit_profile_model.dart';
import 'package:attedance_app/models/profile_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String baseUrl = 'https://your-api-url.com/api';

  static Future<ProfileResponse?> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return profileResponseFromJson(response.body);
    } else {
      return null;
    }
  }

  static Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse(
        '$baseUrl/profile/update',
      ), // adjust if your endpoint is different
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'email': email}),
    );

    if (response.statusCode == 200) {
      final result = editProfileResponseFromJson(response.body);
      return result.message?.toLowerCase().contains('success') ?? false;
    } else {
      return false;
    }
  }
}
