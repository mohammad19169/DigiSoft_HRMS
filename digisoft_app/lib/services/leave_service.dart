import 'dart:convert';
import 'dart:io';
import 'package:digisoft_app/global.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../leave/apply_leave/models/leave_type_model.dart';
import '../leave/apply_leave/models/leave_balance_model.dart';
import '../leave/apply_leave/models/leave_request_model.dart';

class LeaveService {
  static String baseUrl = baseURL;

  Future<List<LeaveType>> getLeaveTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getInt('companyID') ?? 0;
      final token = prefs.getString('token') ?? '';
      
      print('🔍 Getting leave types for company: $companyId');
      print('🔑 Token present: ${token.isNotEmpty}');

      if (companyId == 0) {
        // Debug: Show all stored data to identify the issue
        print('❌ COMPANY ID IS 0 - CHECKING ALL STORED DATA:');
        print('   employeeID: ${prefs.getInt('employeeID')}');
        print('   companyID: ${prefs.getInt('companyID')}');
        print('   companyName: ${prefs.getString('companyName')}');
        print('   createdBy: ${prefs.getString('createdBy')}');
        print('   email: ${prefs.getString('email')}');
        print('   token: ${token.isNotEmpty ? "Present (${token.length} chars)" : "Missing"}');
        
        // Check if maybe the keys are different
        final allKeys = prefs.getKeys();
        print('   All stored keys: $allKeys');
        
        throw Exception('Company ID not found. Please login again.');
      }

      if (token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Use the exact URL that works
      final url = Uri.parse('${baseUrl}hrm/api/LeaveType?companyId=$companyId');
      
      print('🌐 API URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        
        print('✅ API Success: ${body['isSuccess']}');
        print('📝 API Message: ${body['message']}');
        
        if (body['isSuccess'] == true) {
          if (body['data'] != null) {
            final List<dynamic> data = body['data'];
            print('🎉 Loaded ${data.length} leave types');
            
            // Print first leave type for verification
            if (data.isNotEmpty) {
              print('📋 Sample leave type: ${data[0]}');
            }
            
            return data.map((json) => LeaveType.fromJson(json)).toList();
          } else {
            throw Exception('No data received from API');
          }
        } else {
          throw Exception('API Error: ${body['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint not found. Please check the URL.');
      } else {
        print('📦 Error Response Body: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on FormatException catch (e) {
      print('❌ Format Exception: $e');
      throw Exception('Invalid response format from server.');
    } catch (e) {
      print('❌ Error in getLeaveTypes: $e');
      throw Exception('Failed to load leave types: $e');
    }
  }

 Future<LeaveBalance> checkLeaveBalance(int leaveTypeID,int selectedYear) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final employeeID = prefs.getInt('employeeID') ?? 0;
    final companyID = prefs.getInt('companyID') ?? 0;
    final token = prefs.getString('token') ?? '';
    final currentYear = DateTime.now().year;

    print('🔍 Checking balance for leaveTypeID: $leaveTypeID');
    print('👤 EmployeeID: $employeeID, CompanyID: $companyID');

    if (employeeID == 0 || companyID == 0) {
      throw Exception('User data not found. Please login again.');
    }

    final url = Uri.parse(
      '${baseUrl}hrm/api/Leave/balance/$employeeID/$leaveTypeID/$companyID?year=$selectedYear'
    );

    print('🌐 Balance API URL: $url');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('📡 Balance Response Status: ${response.statusCode}');
    print('📦 Balance Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      
      // Check if the response has the standard API wrapper
      if (body.containsKey('isSuccess')) {
        // Standard API response format
        print('✅ Balance API Success: ${body['isSuccess']}');
        print('📝 Balance API Message: ${body['message']}');
        print('💾 Balance API Data: ${body['data']}');
        
        if (body['isSuccess'] == true && body['data'] != null) {
          final balanceData = body['data'];
          print('💰 Balance Data: $balanceData');
          return LeaveBalance.fromJson(balanceData);
        } else {
          final errorMessage = body['message'] ?? 'Balance check failed';
          throw Exception(errorMessage);
        }
      } else if (body.containsKey('employeeID') && body.containsKey('balanceLeave')) {
        // Direct balance data format (no wrapper)
        print('✅ Direct balance data received');
        print('💰 Balance Data: $body');
        return LeaveBalance.fromJson(body);
      } else {
        // Unknown response format
        print('❌ Unknown response format: $body');
        throw Exception('Invalid response format from balance API');
      }
    } else if (response.statusCode == 404) {
      print('❌ Balance API endpoint not found (404)');
      throw Exception('Balance check service is currently unavailable');
    } else {
      print('📦 Balance Error Response: ${response.body}');
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('❌ Error in checkLeaveBalance: $e');
    throw Exception('Failed to check leave balance: $e');
  }
}

Future<Map<String, dynamic>> submitLeaveRequest(LeaveRequest request) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      throw Exception('Authentication token not found. Please login again.');
    }

    final url = Uri.parse('${baseUrl}hrm/api/LeaveRequest');

    // Create multipart request
    var multipartRequest = http.MultipartRequest('POST', url);
    
    // Add headers
    multipartRequest.headers['Authorization'] = 'Bearer $token';
    multipartRequest.headers['Accept'] = 'application/json';
    
    // Add leaveData as form field (as JSON string)
    multipartRequest.fields['leaveData'] = jsonEncode(request.toJson());

    print('🌐 Submit Leave URL: $url');
    print('📤 Request Type: Multipart/Form-Data');
    print('📦 leaveData: ${jsonEncode(request.toJson())}');

    // Send the request
    final streamedResponse = await multipartRequest.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📡 Submit Response Status: ${response.statusCode}');
    print('📦 Submit Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      print('✅ Leave submission result: $result');
      
      // Check for success in the response
      if (result['success'] == true) {
        return {
          'isSuccess': true,
          'message': result['message'] ?? 'Leave submitted successfully',
          'leaveRequestID': result['leaveRequestID'],
        };
      } else {
        throw Exception(result['message'] ?? 'Leave submission failed');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('❌ Error in submitLeaveRequest: $e');
    throw Exception('Failed to submit leave request: $e');
  }
}

  double calculateTotalDays(DateTime fromDate, DateTime toDate, String duration) {
    if (fromDate.isAfter(toDate)) {
      throw Exception('From date cannot be after to date');
    }
    
    final difference = toDate.difference(fromDate).inDays + 1;
    
    if (duration == 'Half Day') {
      return difference * 0.5;
    }
    
    return difference.toDouble();
  }

  // Helper method to debug stored data
  static Future<void> debugStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    print('🐛 DEBUG STORED DATA:');
    print('   employeeID: ${prefs.getInt('employeeID')}');
    print('   companyID: ${prefs.getInt('companyID')}');
    print('   companyName: ${prefs.getString('companyName')}');
    print('   createdBy: ${prefs.getString('createdBy')}');
    print('   email: ${prefs.getString('email')}');
    print('   token: ${prefs.getString('token') != null ? "Present" : "Missing"}');
    
    final allKeys = prefs.getKeys();
    print('   All keys: $allKeys');
    
    for (final key in allKeys) {
      final value = prefs.get(key);
      print('   $key: $value (${value.runtimeType})');
    }
  }
}