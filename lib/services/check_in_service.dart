import 'dart:convert';
import 'package:attedance_app/models/check_in_model.dart';
import 'package:attedance_app/services/endpoint.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CheckInService {
  final String _baseUrl = Endpoint.baseUrl;

  Future<CheckInResponse> checkIn({
    required double lat,
    required double lng,
    required String address,
    String status = 'masuk',
    String? alasanIzin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final url = Uri.parse('$_baseUrl${Endpoint.checkIn}');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = {
      'check_in_lat': lat.toString(),
      'check_in_lng': lng.toString(),
      'check_in_address': address,
      'status': status,
    };

    if (status == 'izin' && alasanIzin != null) {
      body['alasan_izin'] = alasanIzin;
    }

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return checkInResponseFromJson(response.body);
    } else {
      // Tidak peduli response apapun dari server, kasih pesan yang lebih ramah
      throw Exception('Anda sudah melakukan absen hari ini.');
    }
  }
}
