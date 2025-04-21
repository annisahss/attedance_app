import 'dart:convert';
import 'package:attedance_app/models/edit_profile_model.dart';
import 'package:attedance_app/models/profile_model.dart';
import 'package:attedance_app/services/endpoint.dart';
import 'package:attedance_app/services/shared_pref_service.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl = Endpoint.baseUrl;

  /// Ambil data profil user
  static Future<ProfileResponse?> fetchProfile() async {
    final token = await SharedPrefService.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl${Endpoint.profile}'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final profile = profileResponseFromJson(response.body);

      // Simpan ke SharedPreferences (optional)
      await SharedPrefService.saveUserInfo(
        name: profile.data?.name ?? '',
        email: profile.data?.email ?? '',
      );

      return profile;
    } else {
      print('❌ Gagal mengambil profil: ${response.body}');
      return null;
    }
  }

  /// Update profil user (hanya `name`)
  static Future<bool> updateProfile({required String name}) async {
    final token = await SharedPrefService.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl${Endpoint.profile}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) {
      final result = editProfileResponseFromJson(response.body);

      // Perbarui SharedPreferences juga
      await SharedPrefService.saveUserInfo(
        name: result.data?.name ?? name,
        email: result.data?.email ?? '',
      );

      return result.message?.toLowerCase().contains('berhasil') ?? false;
    } else {
      print('❌ Gagal update profil: ${response.body}');
      return false;
    }
  }
}
