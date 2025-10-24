import 'dart:convert';
import 'dart:io';
import 'package:digisoft_app/global.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static  String baseUrl = baseURL;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('${baseUrl}admin/api/Auth/login');
      print('🔐 Login API: $url');
      print('📧 Email: $email');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userEmail': email,
          'password': password,
        }),
      );

      print('📡 Login Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['isSuccess'] == true && body['data'] != null) {
          final data = body['data'];
          
          print('✅ API RESPONSE DATA:');
          print('   Token: ${data['token']?.substring(0, 20)}...');
          print('   Full data keys: ${data.keys}');

          return {
            'success': true,
            'token': data['token'],
            'message': body['message'] ?? 'Login successful',
          };
        } else {
          return {
            'success': false,
            'message': body['message'] ?? 'Invalid credentials'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: Invalid credentials',
        };
      }
    } on SocketException {
      throw Exception('No Internet connection');
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Login failed: $e');
    }
  }
}