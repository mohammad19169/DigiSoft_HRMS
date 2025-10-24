import 'dart:convert';
import 'dart:io';
import 'package:digisoft_app/global.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaveService {
  static String baseUrl = baseURL;
  
  // Get stored employee ID from prefs
  Future<int?> _getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('employeeID');
  }

  Future<int?> _getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('companyID');
  }

  // 1. Get All Leave Requests
  Future<Map<String, dynamic>> getLeaveRequests() async {
    try {
      final companyId = await _getCompanyId();
      final employeeId = await _getEmployeeId();

      final url = Uri.parse('${baseUrl}hrm/api/LeaveRequest?companyId=$companyId&employeeID=$employeeId');
      
      print('📋 Get Leave Requests API: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Get Leave Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        if (body['isSuccess'] == true) {
          return {
            'success': true,
            'data': body['data'] ?? [],
            'message': body['message'] ?? 'Leave requests fetched successfully',
            'totalRecords': (body['data'] as List?)?.length ?? 0,
          };
        } else {
          return {
            'success': false,
            'message': body['message'] ?? 'Failed to fetch leave requests',
            'data': [],
            'totalRecords': 0,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: Failed to fetch leave requests',
          'data': [],
          'totalRecords': 0,
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No Internet connection',
        'data': [],
        'totalRecords': 0,
      };
    } catch (e) {
      print('❌ Get Leave Requests error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch leave requests: $e',
        'data': [],
        'totalRecords': 0,
      };
    }
  }

  // 2. Delete Leave Request
Future<Map<String, dynamic>> deleteLeaveRequest({
  required int leaveRequestID,
  required String updatedBy,
}) async {
  try {
    final url = Uri.parse('${baseUrl}hrm/api/LeaveRequest/$leaveRequestID?updatedBy=$updatedBy');
    
    print('🗑️ Delete Leave API: $url');
    print('📤 Payload: {leaveRequestID: $leaveRequestID, updatedBy: $updatedBy}');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'leaveRequestID': leaveRequestID,
        'updatedBy': updatedBy,
      }),
    );

    print('📡 Delete Leave Response Status: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      
      // FIX: The API returns success even when message says "Failed"
      // So we trust isSuccess field more than the message
      if (body['isSuccess'] == true) {
        return {
          'success': true,
          'message': 'Leave request cancelled successfully', // Custom success message
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to delete leave request',
        };
      }
    } else {
      return {
        'success': false,
        'message': 'HTTP ${response.statusCode}: Failed to delete leave request',
      };
    }
  } catch (e) {
    print('❌ Delete Leave error: $e');
    return {
      'success': false,
      'message': 'Failed to delete leave request: $e',
    };
  }
}

  // Parse leave record for easier use
  Map<String, dynamic> parseLeaveRecord(Map<String, dynamic> record) {
    return {
      'leaveRequestID': record['leaveRequestID'],
      'employeeID': record['employeeID'],
      'leaveTypeID': record['leaveTypeID'],
      'typeName': record['typeName'],
      'companyID': record['companyID'],
      'fromDate': record['fromDate'],
      'toDate': record['toDate'],
      'totalDays': record['totalDays'],
      'reason': record['reason'],
      'status': record['status'],
      'requestDate': record['requestDate'],
      'employeeName': record['employeeName'],
      'duration': record['duration'],
      'employeeImage': record['employeeImage'],
      'attachments': record['attachments'] ?? [],
    };
  }
}