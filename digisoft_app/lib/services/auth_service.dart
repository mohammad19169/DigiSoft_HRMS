import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class AuthService {
  static const String baseUrl = 'http://stagging.digisoftproducts.com/';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('${baseUrl}admin/api/Auth/login');
      
      print('🔄 Attempting login to: $url');
      print('📧 Email: $email');
      print('📦 Request Body: ${jsonEncode({
        'userEmail': email,
        'password': password,
      })}');
      
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
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout - Server took too long to respond');
        },
      );

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('📋 Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isSuccess'] == true) {
          return {
            'success': true,
            'token': data['data']['token'],
            'message': data['message']
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Login failed'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode} - ${response.body}'
        };
      }
    } on SocketException catch (e) {
      print('❌ Socket Exception: $e');
      return {
        'success': false,
        'message': 'No internet connection or server unreachable'
      };
    } on FormatException catch (e) {
      print('❌ Format Exception: $e');
      return {
        'success': false,
        'message': 'Invalid response format from server'
      };
    } on HttpException catch (e) {
      print('❌ HTTP Exception: $e');
      return {
        'success': false,
        'message': 'HTTP error: ${e.message}'
      };
    } catch (e, stackTrace) {
      print('❌ Unknown Error: $e');
      print('📚 Stack Trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }
}