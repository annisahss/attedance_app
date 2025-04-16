
import 'package:attedance_app/models/check_in_model.dart';
import 'package:attedance_app/services/endpoint.dart';
import 'package:http/http.dart' as http;


class CheckInService {
  final String _baseUrl = '${Endpoint.baseUrl}';

  Future<CheckInResponse> checkIn({
    required double lat,
    required double lng,
    required String address,
  }) async {
    final url = Uri.parse('$_baseUrl${Endpoint.checkIn}');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization':
            'Bearer YOUR_TOKEN_HERE', // ganti dengan token dari SharedPreferences
      },
      body: {
        'check_in_lat': lat.toString(),
        'check_in_lng': lng.toString(),
        'check_in_address': address,
      },
    );

    if (response.statusCode == 200) {
      return checkInResponseFromJson(response.body);
    } else {
      throw Exception('Gagal melakukan check-in: ${response.body}');
    }
  }
}
