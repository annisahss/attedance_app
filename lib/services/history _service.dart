import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:attedance_app/services/endpoint.dart';
import 'package:attedance_app/services/shared_pref_service.dart';

class HistoryService {
  /// Ambil riwayat absensi berdasarkan tanggal awal & akhir
  static Future<List<dynamic>> fetchHistory({
    required String startDate,
    required String endDate,
  }) async {
    final token = await SharedPrefService.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final url = Uri.parse(
      '${Endpoint.baseUrl}/api/absen/history?start=$startDate&end=$endDate',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    final jsonData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return jsonData['data'] ?? [];
    } else {
      throw Exception(jsonData['message'] ?? 'Gagal mengambil data absensi.');
    }
  }
}
