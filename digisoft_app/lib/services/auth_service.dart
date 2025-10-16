import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://stagging.digisoftproducts.com/';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('${baseUrl}admin/api/Auth/login');

      print('🔄 Attempting login to: $url');
      print('📧 Email: $email');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'userEmail': email,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout - server took too long');
            },
          );

      print('📊 Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      // ✅ Success (200 OK)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isSuccess'] == true && data['data']?['token'] != null) {
          return {
            'success': true,
            'token': data['data']['token'],
            'message': data['message'] ?? 'Login successful'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Invalid credentials'
          };
        }
      }

      // ❌ Unauthorized (Invalid Credentials)
      else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Invalid email or password. Please try again.'
        };
      }

      // ❌ Client Error (Bad Request)
      else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': 'Invalid request. Please check your input and try again.'
        };
      }

      // ❌ Server Error (500+)
      else if (response.statusCode >= 500) {
        return {
          'success': false,
          'message': 'Server is temporarily unavailable. Please try later.'
        };
      }

      // ❓ Any Other Unexpected Error
      else {
        return {
          'success': false,
          'message':
              'Unexpected error (${response.statusCode}). Please try again.'
        };
      }
    }

    // ⚠️ Network & Format Errors
    on SocketException {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.'
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Invalid response received from server.'
      };
    } on HttpException catch (e) {
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}'
      };
    } catch (e, stackTrace) {
      print('❌ Unknown Error: $e');
      print('📚 Stack Trace: $stackTrace');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again later.'
      };
    }
  }
}
