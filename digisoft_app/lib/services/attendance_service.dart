import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService {
  static const String baseUrl = 'http://stagging.digisoftproducts.com/hrm/api/';

  // Define possible attendance types
  static const String checkInType = 'CheckIn';
  //static const String checkOutType = 'CheckOut';

  // Allowed attendance location with 20 meters radius
  static const double allowedLatitude = 24.8857391;
  static const double allowedLongitude = 67.118721;
  static const double allowedRadiusMeters = 20.0;

  Future<Map<String, dynamic>> markAttendance({
    required int employeeID,
    required int companyID,
    required double latitude,
    required double longitude,
    required String punchTime,
    required String attendanceType,
    String source = 'MobileApp',
    String description = '',
  }) async {
    try {
      // Check if user is within allowed radius
      if (!isWithinAllowedRadius(latitude, longitude)) {
        throw Exception('You are not within the allowed attendance area. Please move to the designated location.');
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // if (attendanceType != checkInType && attendanceType != checkOutType) {
      //   throw Exception('Invalid attendance type. Use CheckIn or CheckOut.');
      // }

      final url = Uri.parse('${baseUrl}Attendance/$attendanceType');

      final String finalDescription = description.isEmpty 
          ? (attendanceType == checkInType ? 'Checked In' : 'Checked Out')
          : description;

      final Map<String, dynamic> requestBody = {
        'employeeID': employeeID.toString(),
        'companyID': companyID.toString(),
        'latitude': latitude,
        'longitude': longitude,
        'punchTime': punchTime,
        'source': source,
        'descIn': attendanceType == checkInType ? finalDescription : '',
        //'descOut': attendanceType == checkOutType ? finalDescription : '',
      };

      print('🌐 $attendanceType API URL: $url');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 $attendanceType Response Status: ${response.statusCode}');
      print('📦 $attendanceType Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        if (responseBody.containsKey('isSuccess')) {
          return {
            'isSuccess': responseBody['isSuccess'] ?? false,
            'message': responseBody['message'] ?? '$attendanceType completed',
            'data': responseBody['data'],
            'attendanceType': attendanceType,
          };
        } else if (responseBody.containsKey('success')) {
          return {
            'isSuccess': responseBody['success'] ?? false,
            'message': responseBody['message'] ?? '$attendanceType completed',
            'data': responseBody,
            'attendanceType': attendanceType,
          };
        } else {
          return {
            'isSuccess': true,
            'message': '$attendanceType completed successfully',
            'data': responseBody,
            'attendanceType': attendanceType,
          };
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Bad request. Please check your data.');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      print('❌ Network error in $attendanceType: $e');
      throw Exception('Network error: Please check your internet connection.');
    } on FormatException catch (e) {
      print('❌ Format error in $attendanceType: $e');
      throw Exception('Invalid response format from server.');
    } catch (e) {
      print('❌ Error in $attendanceType: $e');
      rethrow;
    }
  }

  // Calculate distance between two coordinates in meters (now public)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  bool isWithinAllowedRadius(double userLat, double userLon) {
    double distance = calculateDistance(
      allowedLatitude, 
      allowedLongitude, 
      userLat, 
      userLon
    );
    
    print('📍 Distance from allowed location: ${distance.toStringAsFixed(2)} meters');
    return distance <= allowedRadiusMeters;
  }

  String getCurrentTimeISOString() {
    final now = DateTime.now();
    return now.toIso8601String();
  }

  Future<Map<String, dynamic>> markAttendanceWithCurrentData({
    required double latitude,
    required double longitude,
    required String attendanceType,
    String description = '',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeID = prefs.getInt('employeeID') ?? 0;
      final companyID = prefs.getInt('companyID') ?? 0;

      if (employeeID == 0 || companyID == 0) {
        throw Exception('User data not found. Please login again.');
      }

      final punchTime = getCurrentTimeISOString();

      return await markAttendance(
        employeeID: employeeID,
        companyID: companyID,
        latitude: latitude,
        longitude: longitude,
        punchTime: punchTime,
        attendanceType: attendanceType,
        description: description,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get allowed location info
  Map<String, dynamic> getAllowedLocationInfo() {
    return {
      'latitude': allowedLatitude,
      'longitude': allowedLongitude,
      'radius': allowedRadiusMeters,
      'address': 'Designated Attendance Area'
    };
  }
}

// import 'dart:convert';
// import 'dart:math';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class AttendanceService {
//   static const String baseUrl = 'http://stagging.digisoftproducts.com/hrm/api/';

//   // Allowed attendance location with 20 meters radius
//   static const double allowedLatitude = 24.8815;
//   static const double allowedLongitude = 67.1056;
//   static const double allowedRadiusMeters = 20.0;

//   Future<Map<String, dynamic>> markAttendance({
//     required int employeeID,
//     required int companyID,
//     required double latitude,
//     required double longitude,
//     required String punchTime,
//     String source = 'MobileApp',
//     String description = 'Checked In',
//   }) async {
//     try {
//       // Check if user is within allowed radius
//       if (!isWithinAllowedRadius(latitude, longitude)) {
//         throw Exception('You are not within the allowed attendance area. Please move to the designated location.');
//       }

//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';

//       if (token.isEmpty) {
//         throw Exception('Authentication token not found. Please login again.');
//       }

//       final url = Uri.parse('${baseUrl}Attendance/CheckIn');

//       final Map<String, dynamic> requestBody = {
//         'employeeID': employeeID.toString(),
//         'companyID': companyID.toString(),
//         'latitude': latitude,
//         'longitude': longitude,
//         'punchTime': punchTime,
//         'source': source,
//         'descIn': description,
//       };

//       print('🌐 CheckIn API URL: $url');
//       print('📤 Request Body: ${jsonEncode(requestBody)}');

//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(requestBody),
//       );

//       print('📡 CheckIn Response Status: ${response.statusCode}');
//       print('📦 CheckIn Response Body: ${response.body}');

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
//         if (responseBody.containsKey('isSuccess')) {
//           return {
//             'isSuccess': responseBody['isSuccess'] ?? false,
//             'message': responseBody['message'] ?? 'Check-in completed',
//             'data': responseBody['data'],
//           };
//         } else if (responseBody.containsKey('success')) {
//           return {
//             'isSuccess': responseBody['success'] ?? false,
//             'message': responseBody['message'] ?? 'Check-in completed',
//             'data': responseBody,
//           };
//         } else {
//           return {
//             'isSuccess': true,
//             'message': 'Check-in completed successfully',
//             'data': responseBody,
//           };
//         }
//       } else if (response.statusCode == 401) {
//         throw Exception('Authentication failed. Please login again.');
//       } else if (response.statusCode == 400) {
//         final errorBody = jsonDecode(response.body);
//         throw Exception(errorBody['message'] ?? 'Bad request. Please check your data.');
//       } else {
//         throw Exception('HTTP ${response.statusCode}: ${response.body}');
//       }
//     } on http.ClientException catch (e) {
//       print('❌ Network error in checkIn: $e');
//       throw Exception('Network error: Please check your internet connection.');
//     } on FormatException catch (e) {
//       print('❌ Format error in checkIn: $e');
//       throw Exception('Invalid response format from server.');
//     } catch (e) {
//       print('❌ Error in checkIn: $e');
//       rethrow;
//     }
//   }

//   // Get Today's Attendance
//   Future<Map<String, dynamic>> getTodayAttendance() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//       final employeeID = prefs.getInt('employeeID') ?? 0;

//       if (token.isEmpty) {
//         throw Exception('Authentication token not found. Please login again.');
//       }

//       if (employeeID == 0) {
//         throw Exception('Employee ID not found. Please login again.');
//       }

//       final url = Uri.parse('${baseUrl}Attendance/Today?employeeId=$employeeID');

//       print('🌐 Get Today Attendance API URL: $url');
//       print('🔑 Token Present: ${token.isNotEmpty}');

//       final response = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       print('📡 Today Attendance Response Status: ${response.statusCode}');
//       print('📦 Today Attendance Response Body: ${response.body}');

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
//         return {
//           'isSuccess': responseBody['isSuccess'] ?? true,
//           'message': responseBody['message'] ?? '',
//           'data': responseBody['data'],
//           'hasCheckedIn': responseBody['data'] != null && responseBody['data']['checkInTime'] != null,
//           'checkInTime': responseBody['data'] != null ? responseBody['data']['checkInTime'] : null,
//         };
//       } else if (response.statusCode == 401) {
//         throw Exception('Authentication failed. Please login again.');
//       } else if (response.statusCode == 404) {
//         // No attendance record found for today
//         return {
//           'isSuccess': true,
//           'message': 'No attendance record found for today',
//           'data': null,
//           'hasCheckedIn': false,
//           'checkInTime': null,
//         };
//       } else {
//         throw Exception('HTTP ${response.statusCode}: ${response.body}');
//       }
//     } on http.ClientException catch (e) {
//       print('❌ Network error in getTodayAttendance: $e');
//       throw Exception('Network error: Please check your internet connection.');
//     } on FormatException catch (e) {
//       print('❌ Format error in getTodayAttendance: $e');
//       throw Exception('Invalid response format from server.');
//     } catch (e) {
//       print('❌ Error in getTodayAttendance: $e');
//       rethrow;
//     }
//   }

//   // Calculate distance between two coordinates in meters (now public)
//   double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     const double earthRadius = 6371000; // meters

//     double dLat = _toRadians(lat2 - lat1);
//     double dLon = _toRadians(lon2 - lon1);

//     double a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
//         sin(dLon / 2) * sin(dLon / 2);
    
//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
//     return earthRadius * c;
//   }

//   double _toRadians(double degrees) {
//     return degrees * pi / 180;
//   }

//   bool isWithinAllowedRadius(double userLat, double userLon) {
//     double distance = calculateDistance(
//       allowedLatitude, 
//       allowedLongitude, 
//       userLat, 
//       userLon
//     );
    
//     print('📍 Distance from allowed location: ${distance.toStringAsFixed(2)} meters');
//     return distance <= allowedRadiusMeters;
//   }

//   String getCurrentTimeISOString() {
//     final now = DateTime.now();
//     return now.toIso8601String();
//   }

//   Future<Map<String, dynamic>> markAttendanceWithCurrentData({
//     required double latitude,
//     required double longitude,
//     String description = 'Checked In',
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final employeeID = prefs.getInt('employeeID') ?? 0;
//       final companyID = prefs.getInt('companyID') ?? 0;

//       if (employeeID == 0 || companyID == 0) {
//         throw Exception('User data not found. Please login again.');
//       }

//       final punchTime = getCurrentTimeISOString();

//       return await markAttendance(
//         employeeID: employeeID,
//         companyID: companyID,
//         latitude: latitude,
//         longitude: longitude,
//         punchTime: punchTime,
//         description: description,
//       );
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // Get allowed location info
//   Map<String, dynamic> getAllowedLocationInfo() {
//     return {
//       'latitude': allowedLatitude,
//       'longitude': allowedLongitude,
//       'radius': allowedRadiusMeters,
//       'address': 'Designated Attendance Area'
//     };
//   }
// }