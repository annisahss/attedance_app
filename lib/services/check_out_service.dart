import 'package:attedance_app/models/check_out_model.dart';
import 'package:attedance_app/services/endpoint.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CheckOutService {
  final String baseUrl = '${Endpoint.baseUrl}';

  Future<CheckOutResponse?> checkOut({
    required double lat,
    required double lng,
    required String location,
    required String address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl${Endpoint.checkOut}');
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
      return checkOutResponseFromJson(
        response.body,
      ); // untuk case "sudah checkout"
    }
  }
}
