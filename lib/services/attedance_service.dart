import 'dart:convert';
import 'package:attedance_app/models/check_in_model.dart';
import 'package:attedance_app/models/check_out_model.dart';
import 'package:attedance_app/services/endpoint.dart';
import 'package:attedance_app/services/shared_pref_service.dart';
import 'package:http/http.dart' as http;

class AttendanceService {
  final String _baseUrl = Endpoint.baseUrl;

  /// Check-In (Masuk / Izin)
  Future<CheckInResponse> checkIn({
    required double lat,
    required double lng,
    required String address,
    String status = 'masuk',
    String? alasanIzin,
  }) async {
    final token = await SharedPrefService.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final url = Uri.parse('$_baseUrl${Endpoint.checkIn}');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
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
      final responseData = jsonDecode(response.body);
      throw Exception('❌ Gagal Check-In: ${responseData['message']}');
    }
  }

  /// Check-Out
  Future<CheckOutResponse?> checkOut({
    required double lat,
    required double lng,
    required String location,
    required String address,
  }) async {
    final token = await SharedPrefService.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final url = Uri.parse('$_baseUrl${Endpoint.checkOut}');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    final body = {
      'check_out_lat': lat.toString(),
      'check_out_lng': lng.toString(),
      'check_out_location': location,
      'check_out_address': address,
    };

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return checkOutResponseFromJson(response.body);
    } else {
      final responseData = jsonDecode(response.body);
      print('❌ Gagal Check-Out: ${responseData['message']}');
      return checkOutResponseFromJson(
        response.body,
      ); // tetap parse meskipun gagal
    }
  }
}
