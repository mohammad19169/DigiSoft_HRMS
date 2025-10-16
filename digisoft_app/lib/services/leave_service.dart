import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaveService {
  static const String baseUrl = 'http://stagging.digisoftproducts.com/';

  Future<bool> submitLeave({
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        print('❌ No token found, please login again.');
        return false;
      }

      final url = Uri.parse('${baseUrl}admin/api/Leave/submit');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fromDate': fromDate,
          'toDate': toDate,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Leave request submitted successfully');
        return true;
      } else {
        print('❌ Failed to submit leave: ${response.body}');
        return false;
      }
    } catch (e) {
      print('⚠️ Exception while submitting leave: $e');
      return false;
    }
  }
}
