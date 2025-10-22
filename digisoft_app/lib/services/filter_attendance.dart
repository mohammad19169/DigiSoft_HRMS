import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceFilterService {
  static const String baseUrl = 'http://stagging.digisoftproducts.com/';
  
  // Prefs keys
  static const String companyIdKey = 'companyID';
  static const String employeeIdKey = 'employeeID';

  Future<int> _getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(companyIdKey) ?? 1; 
  }

  Future<int?> _getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(employeeIdKey);
  }

  Future<Map<String, dynamic>> getAttendanceByFilter({
    DateTime? fromDate,
    DateTime? toDate,
    int? employeeId,
  }) async {
    try {
      final companyId = await _getCompanyId();
      final currentEmployeeId = await _getEmployeeId();


      final targetEmployeeId = employeeId ?? currentEmployeeId;

      // Format dates (default to current month if not provided)
      final String fromDateStr = fromDate != null 
          ? _formatDate(fromDate) 
          : _formatDate(DateTime.now().subtract(const Duration(days: 30)));
      
      final String toDateStr = toDate != null 
          ? _formatDate(toDate) 
          : _formatDate(DateTime.now());

      // Build URL with parameters
      final Map<String, String> queryParams = {
        'companyId': companyId.toString(), // Use actual company ID from prefs
        'fromDate': fromDateStr,
        'toDate': toDateStr,
      };

      // Add employeeId only if available
      if (targetEmployeeId != null) {
        queryParams['employeeId'] = targetEmployeeId.toString();
      }

      final uri = Uri.parse('${baseUrl}hrm/api/Attendance/GetAttendanceByFilter')
          .replace(queryParameters: queryParams);

      print('📊 Attendance Filter API: $uri');
      print('🔍 Query Parameters: $queryParams');
      print('🏢 Using Company ID: $companyId');
      print('👤 Using Employee ID: $targetEmployeeId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // No Authorization header needed
        },
      );

      print('📡 Attendance Filter Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        if (body['isSuccess'] == true) {
          return {
            'success': true,
            'data': body['data'] ?? [],
            'message': body['message'] ?? 'Attendance data fetched successfully',
            'totalRecords': (body['data'] as List?)?.length ?? 0,
          };
        } else {
          return {
            'success': false,
            'message': body['message'] ?? 'Failed to fetch attendance data',
            'data': [],
            'totalRecords': 0,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: Failed to fetch attendance data',
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
      print('❌ Attendance Filter error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch attendance data: $e',
        'data': [],
        'totalRecords': 0,
      };
    }
  }

  // Get current month attendance (convenience method)
  Future<Map<String, dynamic>> getCurrentMonthAttendance({int? employeeId}) async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return getAttendanceByFilter(
      fromDate: firstDayOfMonth,
      toDate: lastDayOfMonth,
      employeeId: employeeId,
    );
  }

  // Get today's attendance (convenience method)
  Future<Map<String, dynamic>> getTodayAttendance({int? employeeId}) async {
    final today = DateTime.now();
    return getAttendanceByFilter(
      fromDate: today,
      toDate: today,
      employeeId: employeeId,
    );
  }

  // Get attendance for specific month
  Future<Map<String, dynamic>> getAttendanceForMonth(int year, int month, {int? employeeId}) async {
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    return getAttendanceByFilter(
      fromDate: firstDayOfMonth,
      toDate: lastDayOfMonth,
      employeeId: employeeId,
    );
  }

  // Get attendance for date range
  Future<Map<String, dynamic>> getAttendanceForDateRange(DateTime startDate, DateTime endDate, {int? employeeId}) async {
    return getAttendanceByFilter(
      fromDate: startDate,
      toDate: endDate,
      employeeId: employeeId,
    );
  }

  // Helper method to format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Parse attendance data into more usable format
  Map<String, dynamic> parseAttendanceRecord(Map<String, dynamic> record) {
    return {
      'attendanceID': record['attendanceID'],
      'employeeID': record['employeeID'],
      'companyID': record['companyID'],
      'attendanceDate': record['attendanceDate'],
      'employeeName': record['employeeName'],
      'departmentName': record['departmentName'],
      'designationName': record['designationName'],
      'shiftName': record['shiftName'],
      'statusName': record['statusName'],
      'scheduledStartTime': record['scheduledStartTime'],
      'scheduledEndTime': record['scheduledEndTime'],
      'actualStartTime': record['actualStartTime'],
      'actualEndTime': record['actualEndTime'],
      'lateBy': record['lateBy'],
      'earlyBy': record['earlyBy'],
      'overTime': record['overTime'],
      'totalWorkedSeconds': record['totalWorkedSeconds'],
      'isLate': record['isLate'] ?? false,
      'isHalfDay': record['isHalfDay'] ?? false,
      'isAbsent': record['isAbsent'] ?? false,
      'isOnLeave': record['isOnLeave'] ?? false,
      'checkInLocation': record['checkInLocation'],
      'checkOutLocation': record['checkOutLocation'],
      'checkInLatitude': record['checkInLatitude'],
      'checkInLongitude': record['checkInLongitude'],
      'checkOutLatitude': record['checkOutLatitude'],
      'checkOutLongitude': record['checkOutLongitude'],
      'remarks': record['remarks'],
      'attendanceSource': record['attendanceSource'],
      'employeeImage': record['employeeImage'],
    };
  }

  // Calculate statistics from attendance data
// Update the calculateAttendanceStatistics method in your AttendanceFilterService
Map<String, dynamic> calculateAttendanceStatistics(List<dynamic> attendanceData) {
  int presentDays = 0;
  int absentDays = 0;
  int halfDays = 0;
  int lateDays = 0;
  int leaveDays = 0;
  double totalWorkingHours = 0;

  for (var record in attendanceData) {
    final parsedRecord = parseAttendanceRecord(record);
    final statusName = (parsedRecord['statusName'] ?? '').toString().toLowerCase();
    
    // Debug each record
    print('📊 RECORD ANALYSIS:');
    print('   Date: ${parsedRecord['attendanceDate']}');
    print('   Status: $statusName');
    print('   isAbsent: ${parsedRecord['isAbsent']}');
    print('   isOnLeave: ${parsedRecord['isOnLeave']}');
    print('   isHalfDay: ${parsedRecord['isHalfDay']}');
    print('   isLate: ${parsedRecord['isLate']}');
    print('   Check In: ${parsedRecord['actualStartTime']}');
    
    // Use mutually exclusive categories - each day can only be in ONE category
    if (parsedRecord['isAbsent'] == true || statusName.contains('absent')) {
      absentDays++;
      print('   → Counted as: ABSENT');
    } 
    else if (parsedRecord['isOnLeave'] == true || statusName.contains('leave')) {
      leaveDays++;
      print('   → Counted as: LEAVE');
    } 
    else if (parsedRecord['isHalfDay'] == true || statusName.contains('half')) {
      halfDays++;
      print('   → Counted as: HALF DAY');
    }
    else if (parsedRecord['actualStartTime'] != null) {
      // Only count as present if they actually checked in
      presentDays++;
      
      // Late is a sub-category of present days
      if (parsedRecord['isLate'] == true || statusName.contains('late')) {
        lateDays++;
        print('   → Counted as: PRESENT (LATE)');
      } else {
        print('   → Counted as: PRESENT (ON TIME)');
      }
      
      // Calculate working hours if both check-in and check-out are available
      if (parsedRecord['actualStartTime'] != null && parsedRecord['actualEndTime'] != null) {
        try {
          final startTime = DateTime.parse(parsedRecord['actualStartTime']);
          final endTime = DateTime.parse(parsedRecord['actualEndTime']);
          final hours = endTime.difference(startTime).inHours.toDouble();
          totalWorkingHours += hours;
          print('   → Working Hours: $hours');
        } catch (e) {
          print('   → Error calculating working hours: $e');
        }
      }
    }
    else {
      // If no check-in and not marked as anything else, count as absent
      absentDays++;
      print('   → Counted as: ABSENT (No check-in)');
    }
    
    print('   ---');
  }

  final stats = {
    'presentDays': presentDays,
    'absentDays': absentDays,
    'halfDays': halfDays,
    'lateDays': lateDays, // This is a subset of presentDays, not additional days
    'leaveDays': leaveDays,
    'totalWorkingHours': totalWorkingHours,
    'totalDays': attendanceData.length,
  };

  print('📈 FINAL STATISTICS:');
  print('   Total Records: ${stats['totalDays']}');
  print('   Present: ${stats['presentDays']}');
  print('   Absent: ${stats['absentDays']}');
  print('   Half Days: ${stats['halfDays']}');
  print('   Late (subset of present): ${stats['lateDays']}');
  print('   Leave: ${stats['leaveDays']}');
  print('   Total Working Hours: ${stats['totalWorkingHours']}');
  
  // Verify the math
  final calculatedTotal = presentDays + absentDays + halfDays + leaveDays;
  print('   VERIFICATION: $presentDays + $absentDays + $halfDays + $leaveDays = $calculatedTotal (should equal ${stats['totalDays']})');

  return stats;
}

  // Get stored company info for debugging
  Future<Map<String, dynamic>> getStoredCompanyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'companyId': prefs.getInt(companyIdKey),
      'employeeId': prefs.getInt(employeeIdKey),
      'companyName': prefs.getString('CompanyName'),
      'userName': prefs.getString('UserName'),
    };
  }
}