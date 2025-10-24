// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'package:digisoft_app/global.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class AttendanceService {
//   static String baseUrl = baseURL;
  
//   // Attendance Types
//   static const String checkInType = 'CheckIn';
//   static const String checkOutType = 'CheckOut';

//   // Fix the base URL by removing any trailing slashes
//   static String get _baseUrl {
//     String url = baseURL;
//     if (url.endsWith('/')) {
//       url = url.substring(0, url.length - 1);
//     }
//     return url;
//   }

//   // Get user data from SharedPreferences - FIXED: Handle GeoFenceID properly
//   static Future<Map<String, dynamic>> _getUserDataFromPrefs() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
      
//       // Handle both string and int types
//       final geoFenceID = _getStringFromPrefs(prefs, 'GeoFenceID'); // FIXED: Get as string
//       final employeeID = _getIntFromPrefs(prefs, 'employeeID');
//       final companyID = _getIntFromPrefs(prefs, 'companyID');
//       final token = prefs.getString('token') ?? '';
      
//       print('🔍 Retrieved from SharedPreferences:');
//       print('   GeoFenceID: $geoFenceID');
//       print('   EmployeeID: $employeeID');
//       print('   CompanyID: $companyID');
//       print('   Token length: ${token.length}');
      
//       if (employeeID == 0 || companyID == 0 || token.isEmpty) {
//         throw Exception('Required data not found in SharedPreferences');
//       }
      
//       return {
//         'geoFenceID': geoFenceID, // Now as string
//         'employeeID': employeeID,
//         'companyID': companyID,
//         'token': token,
//       };
//     } catch (e) {
//       print('❌ Error getting data from SharedPreferences: $e');
//       rethrow;
//     }
//   }

//   // Helper method to get integer from prefs handling both string and int
//   static int _getIntFromPrefs(SharedPreferences prefs, String key) {
//     try {
//       // First try to get as int
//       final intValue = prefs.getInt(key);
//       if (intValue != null) return intValue;
      
//       // If not found as int, try as string
//       final stringValue = prefs.getString(key);
//       if (stringValue != null && stringValue.isNotEmpty) {
//         return int.tryParse(stringValue) ?? 0;
//       }
      
//       return 0;
//     } catch (e) {
//       print('❌ Error getting $key from prefs: $e');
//       return 0;
//     }
//   }

//   // Helper method to get string from prefs - NEW METHOD
//   static String _getStringFromPrefs(SharedPreferences prefs, String key) {
//     try {
//       // First try to get as string
//       final stringValue = prefs.getString(key);
//       if (stringValue != null) return stringValue;
      
//       // If not found as string, try as int and convert to string
//       final intValue = prefs.getInt(key);
//       if (intValue != null) return intValue.toString();
      
//       return '';
//     } catch (e) {
//       print('❌ Error getting $key from prefs: $e');
//       return '';
//     }
//   }

//   // Get all geofence locations for maps - FIXED: Handle empty GeoFenceID
//   static Future<List<Map<String, dynamic>>> getGeofenceLocationsInfo() async {
//     try {
//       final userData = await _getUserDataFromPrefs();
//       final geoFenceID = userData['geoFenceID']!;
      
//       // Check if GeoFenceID is valid
//       if (geoFenceID.isEmpty || geoFenceID == '0') {
//         print('⚠️ No valid GeoFenceID found: $geoFenceID');
//         return [];
//       }
      
//       // Since we don't have GetAll endpoint, get the single location by ID
//       final url = '$_baseUrl/hrm/api/GeoFenceLocation/Getbyid/$geoFenceID';
//       print('📡 Getting geofence location: $url');

//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       ).timeout(Duration(seconds: 30));

//       print('📊 Geofence Location Response Status: ${response.statusCode}');
//       print('📊 Geofence Location Response Body: ${response.body}');

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         final Map<String, dynamic> data = responseData['data'] ?? {};
        
//         // Convert single location to list format for UI
//         final List<Map<String, dynamic>> locations = [];
        
//         if (data.isNotEmpty && data['locationID'] != null) {
//           locations.add({
//             'locationID': data['locationID'] ?? 0,
//             'locationName': data['locationName'] ?? '',
//             'latitude': (data['latitude'] ?? 0.0).toDouble(),
//             'longitude': (data['longitude'] ?? 0.0).toDouble(),
//             'radius': (data['radiusInMeters'] ?? 0.0).toDouble(),
//             'isActive': data['isActive'] ?? false,
//           });
          
//           print('✅ Geofence location retrieved successfully: ${data['locationName']}');
//         }
        
//         return locations;
//       } else {
//         print('⚠️ Failed to load geofence location. Status: ${response.statusCode}');
//         return [];
//       }
//     } catch (e) {
//       print('❌ Error loading geofence location: $e');
//       // Return empty list instead of throwing to prevent UI crashes
//       return [];
//     }
//   }

//   // Check if within any geofence (for multiple locations) - FIXED: Handle no geofence scenario
//   static Future<bool> isWithinAnyGeofenceLocation(double userLat, double userLng, List<dynamic> geofenceLocations) async {
//     try {
//       print('📍 Checking if within any geofence...');
//       print('📍 User Location: $userLat, $userLng');
//       print('📍 Total geofence locations: ${geofenceLocations.length}');

//       // If no geofence locations, try to get the single location
//       if (geofenceLocations.isEmpty) {
//         print('⚠️ No geofence locations in list, fetching single location...');
//         final locations = await getGeofenceLocationsInfo();
//         if (locations.isEmpty) {
//           print('❌ No geofence locations available at all');
//           return false;
//         }
//         geofenceLocations = locations;
//       }

//       for (final location in geofenceLocations) {
//         if (location['isActive'] == true) {
//           final distance = _calculateDistance(
//             userLat,
//             userLng,
//             location['latitude'],
//             location['longitude'],
//           );
          
//           print('📍 Checking location: ${location['locationName']}');
//           print('📍 Distance: ${distance.toStringAsFixed(2)}m, Radius: ${location['radius']}m');
          
//           if (distance <= location['radius']) {
//             print('✅ User is within ${location['locationName']}');
//             return true;
//           }
//         }
//       }
      
//       print('❌ User is not within any active geofence');
//       return false;
//     } catch (e) {
//       print('❌ Error checking geofence location: $e');
//       return false;
//     }
//   }

//   // Get today's attendance status
//   static Future<Map<String, dynamic>> getTodayAttendance() async {
//     try {
//       final userData = await _getUserDataFromPrefs();
//       final employeeID = userData['employeeID']!;
//       final companyID = userData['companyID']!;
//       final token = userData['token']!;
      
//       final today = DateTime.now().toIso8601String().split('T')[0];
//       final url = '$_baseUrl/hrm/api/Attendance/GetTodayAttendance/$employeeID/$companyID?date=$today';
      
//       print('📡 Getting today attendance: $url');

//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       ).timeout(Duration(seconds: 30));

//       print('📊 Today Attendance Response Status: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         final List<dynamic> data = responseData['data'] ?? [];
        
//         bool hasCheckedIn = false;
//         bool hasCheckedOut = false;
        
//         for (final record in data) {
//           if (record['checkInTime'] != null) hasCheckedIn = true;
//           if (record['checkOutTime'] != null) hasCheckedOut = true;
//         }
        
//         print('✅ Today attendance status - Checked In: $hasCheckedIn, Checked Out: $hasCheckedOut');
        
//         return {
//           'hasCheckedIn': hasCheckedIn,
//           'hasCheckedOut': hasCheckedOut,
//           'records': data,
//         };
//       } else {
//         // Return default values instead of throwing for 404
//         print('⚠️ Today attendance not found (404), returning default values');
//         return {
//           'hasCheckedIn': false,
//           'hasCheckedOut': false,
//           'records': [],
//         };
//       }
//     } catch (e) {
//       print('❌ Error loading today attendance: $e');
//       return {
//         'hasCheckedIn': false,
//         'hasCheckedOut': false,
//         'records': [],
//       };
//     }
//   }

//   // Mark attendance with current data - FIXED: Handle no geofence scenario
//   static Future<Map<String, dynamic>> markAttendanceWithCurrentData({
//     required double latitude,
//     required double longitude,
//     required String attendanceType,
//     String source = 'MobileApp',
//     String description = '',
//   }) async {
//     try {
//       final userData = await _getUserDataFromPrefs();
//       final employeeID = userData['employeeID']!;
//       final companyID = userData['companyID']!;
//       final token = userData['token']!;
      
//       // Get geofence location name - FIXED: Handle no geofence scenario
//       String geoLocation = 'Unknown Location';
//       bool isWithinGeofence = false;
      
//       try {
//         final geofenceLocations = await getGeofenceLocationsInfo();
//         isWithinGeofence = await isWithinAnyGeofenceLocation(latitude, longitude, geofenceLocations);
//         if (isWithinGeofence && geofenceLocations.isNotEmpty) {
//           geoLocation = geofenceLocations.first['locationName'] ?? 'Office Location';
//         } else if (geofenceLocations.isEmpty) {
//           // If no geofence is configured, allow attendance from anywhere
//           print('⚠️ No geofence configured, allowing attendance from any location');
//           geoLocation = 'No Geofence Configured';
//           isWithinGeofence = true; // Allow attendance if no geofence
//         }
//       } catch (e) {
//         print('⚠️ Error checking geofence: $e');
//         // If geofence check fails, still allow attendance but log the issue
//         isWithinGeofence = true;
//         geoLocation = 'Geofence Check Failed';
//       }

//       // Check if within geofence (only if geofence is configured)
//       final geofenceLocations = await getGeofenceLocationsInfo();
//       if (geofenceLocations.isNotEmpty && !isWithinGeofence) {
//         return {
//           'isSuccess': false,
//           'message': 'You are not within any allowed attendance area',
//           'data': null,
//           'statusCode': 400,
//         };
//       }

//       // Prepare request body based on attendance type
//       final Map<String, dynamic> requestBody;
      
//       if (attendanceType == checkInType) {
//         requestBody = {
//           "employeeID": employeeID.toString(),
//           "companyID": companyID.toString(),
//           "latitude": latitude,
//           "longitude": longitude,
//           "punchTime": DateTime.now().toIso8601String(),
//           "ipAddress": await _getIPAddress(),
//           "source": source,
//           "descIn": description.isNotEmpty ? description : 'Checked In from Mobile App',
//           "geoLocationIn": geoLocation,
//         };
//       } else {
//         requestBody = {
//           "employeeID": employeeID.toString(),
//           "companyID": companyID.toString(),
//           "latitude": latitude,
//           "longitude": longitude,
//           "punchTime": DateTime.now().toIso8601String(),
//           "ipAddress": await _getIPAddress(),
//           "source": source,
//           "descin": description.isNotEmpty ? description : 'Checked Out from Mobile App',
//           "geoLocationOut": geoLocation,
//         };
//       }

//       final String endpoint = attendanceType == checkInType 
//           ? 'CheckIn' 
//           : 'CheckOut';
          
//       final url = '$_baseUrl/hrm/api/Attendance/$endpoint';
//       print('📡 Marking attendance ($attendanceType): $url');
//       print('📦 Request Body: ${json.encode(requestBody)}');

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode(requestBody),
//       ).timeout(Duration(seconds: 30));

//       print('📊 Attendance Response Status: ${response.statusCode}');
//       print('📊 Attendance Response Body: ${response.body}');

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         return {
//           'isSuccess': responseData['isSuccess'] ?? false,
//           'message': responseData['message'] ?? 'Attendance marked successfully',
//           'data': responseData['data'],
//           'statusCode': responseData['statusCode'] ?? 200,
//         };
//       } else if (response.statusCode == 400) {
//         final Map<String, dynamic> errorData = json.decode(response.body);
//         return {
//           'isSuccess': false,
//           'message': errorData['message'] ?? 'Bad request',
//           'data': null,
//           'statusCode': 400,
//         };
//       } else if (response.statusCode == 401) {
//         return {
//           'isSuccess': false,
//           'message': 'Unauthorized - Please login again',
//           'data': null,
//           'statusCode': 401,
//         };
//       } else {
//         return {
//           'isSuccess': false,
//           'message': 'Failed to mark attendance. Status: ${response.statusCode}',
//           'data': null,
//           'statusCode': response.statusCode,
//         };
//       }
//     } catch (e) {
//       print('❌ Unexpected error during attendance: $e');
//       return {
//         'isSuccess': false,
//         'message': 'Failed to mark attendance: $e',
//         'data': null,
//         'statusCode': 0,
//       };
//     }
//   }

//   // Get IP Address (placeholder implementation)
//   static Future<String> _getIPAddress() async {
//     try {
//       return '192.168.1.1';
//     } catch (e) {
//       return 'Unknown';
//     }
//   }

//   // Calculate distance between two coordinates using Haversine formula
//   static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     const earthRadius = 6371000; // meters

//     final dLat = _toRadians(lat2 - lat1);
//     final dLon = _toRadians(lon2 - lon1);

//     final a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    
//     final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     final distance = earthRadius * c;

//     return distance;
//   }

//   static double _toRadians(double degree) {
//     return degree * pi / 180;
//   }
// }

// // Response Models (keep the same)
// class GeoFenceResponse {
//   final int statusCode;
//   final String message;
//   final GeoFenceData data;
//   final List<dynamic> errors;
//   final bool isSuccess;
//   final String timestamp;

//   GeoFenceResponse({
//     required this.statusCode,
//     required this.message,
//     required this.data,
//     required this.errors,
//     required this.isSuccess,
//     required this.timestamp,
//   });

//   factory GeoFenceResponse.fromJson(Map<String, dynamic> json) {
//     return GeoFenceResponse(
//       statusCode: json['statusCode'] ?? 0,
//       message: json['message'] ?? '',
//       data: GeoFenceData.fromJson(json['data'] ?? {}),
//       errors: json['errors'] ?? [],
//       isSuccess: json['isSuccess'] ?? false,
//       timestamp: json['timestamp'] ?? '',
//     );
//   }
// }

// class GeoFenceData {
//   final int locationID;
//   final int companyID;
//   final String locationName;
//   final double latitude;
//   final double longitude;
//   final double radiusInMeters;
//   final bool isActive;
//   final String createdOn;
//   final String createdBy;
//   final String? updatedOn;
//   final String? updatedBy;

//   GeoFenceData({
//     required this.locationID,
//     required this.companyID,
//     required this.locationName,
//     required this.latitude,
//     required this.longitude,
//     required this.radiusInMeters,
//     required this.isActive,
//     required this.createdOn,
//     required this.createdBy,
//     this.updatedOn,
//     this.updatedBy,
//   });

//   factory GeoFenceData.fromJson(Map<String, dynamic> json) {
//     return GeoFenceData(
//       locationID: json['locationID'] ?? 0,
//       companyID: json['companyID'] ?? 0,
//       locationName: json['locationName'] ?? '',
//       latitude: (json['latitude'] ?? 0.0).toDouble(),
//       longitude: (json['longitude'] ?? 0.0).toDouble(),
//       radiusInMeters: (json['radiusInMeters'] ?? 0.0).toDouble(),
//       isActive: json['isActive'] ?? false,
//       createdOn: json['createdOn'] ?? '',
//       createdBy: json['createdBy'] ?? '',
//       updatedOn: json['updatedOn'],
//       updatedBy: json['updatedBy'],
//     );
//   }
// }

// class AttendanceResponse {
//   final int statusCode;
//   final String message;
//   final dynamic data;
//   final List<dynamic> errors;
//   final bool isSuccess;
//   final String timestamp;

//   AttendanceResponse({
//     required this.statusCode,
//     required this.message,
//     required this.data,
//     required this.errors,
//     required this.isSuccess,
//     required this.timestamp,
//   });

//   factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
//     return AttendanceResponse(
//       statusCode: json['statusCode'] ?? 0,
//       message: json['message'] ?? '',
//       data: json['data'],
//       errors: json['errors'] ?? [],
//       isSuccess: json['isSuccess'] ?? false,
//       timestamp: json['timestamp'] ?? '',
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:digisoft_app/global.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService {
  static String baseUrl = baseURL;
  
  // Attendance Types
  static const String checkInType = 'CheckIn';
  static const String checkOutType = 'CheckOut';

  // Fix the base URL by removing any trailing slashes
  static String get _baseUrl {
    String url = baseURL;
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  // Get user data from SharedPreferences
  static Future<Map<String, dynamic>> _getUserDataFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Handle both string and int types
      final geoFenceID = _getStringFromPrefs(prefs, 'GeoFenceID');
      final employeeID = _getIntFromPrefs(prefs, 'employeeID');
      final companyID = _getIntFromPrefs(prefs, 'companyID');
      final token = prefs.getString('token') ?? '';
      final createdBy = prefs.getString('createdBy') ?? 'hrm';
      
      print('🔍 Retrieved from SharedPreferences:');
      print('   GeoFenceID: $geoFenceID');
      print('   EmployeeID: $employeeID');
      print('   CompanyID: $companyID');
      print('   CreatedBy: $createdBy');
      print('   Token length: ${token.length}');
      
      if (employeeID == 0 || companyID == 0 || token.isEmpty) {
        throw Exception('Required data not found in SharedPreferences');
      }
      
      return {
        'geoFenceID': geoFenceID,
        'employeeID': employeeID,
        'companyID': companyID,
        'token': token,
        'createdBy': createdBy,
      };
    } catch (e) {
      print('❌ Error getting data from SharedPreferences: $e');
      rethrow;
    }
  }

  // Helper method to get integer from prefs handling both string and int
  static int _getIntFromPrefs(SharedPreferences prefs, String key) {
    try {
      // First try to get as int
      final intValue = prefs.getInt(key);
      if (intValue != null) return intValue;
      
      // If not found as int, try as string
      final stringValue = prefs.getString(key);
      if (stringValue != null && stringValue.isNotEmpty) {
        return int.tryParse(stringValue) ?? 0;
      }
      
      return 0;
    } catch (e) {
      print('❌ Error getting $key from prefs: $e');
      return 0;
    }
  }

  // Helper method to get string from prefs
  static String _getStringFromPrefs(SharedPreferences prefs, String key) {
    try {
      // First try to get as string
      final stringValue = prefs.getString(key);
      if (stringValue != null) return stringValue;
      
      // If not found as string, try as int and convert to string
      final intValue = prefs.getInt(key);
      if (intValue != null) return intValue.toString();
      
      return '';
    } catch (e) {
      print('❌ Error getting $key from prefs: $e');
      return '';
    }
  }

  // Get all geofence locations for maps
  static Future<List<Map<String, dynamic>>> getGeofenceLocationsInfo() async {
    try {
      final userData = await _getUserDataFromPrefs();
      final geoFenceID = userData['geoFenceID']!;
      
      // Check if GeoFenceID is valid
      if (geoFenceID.isEmpty || geoFenceID == '0') {
        print('⚠️ No valid GeoFenceID found: $geoFenceID');
        return [];
      }
      
      // Since we don't have GetAll endpoint, get the single location by ID
      final url = '$_baseUrl/hrm/api/GeoFenceLocation/Getbyid/$geoFenceID';
      print('📡 Getting geofence location: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('📊 Geofence Location Response Status: ${response.statusCode}');
      print('📊 Geofence Location Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> data = responseData['data'] ?? {};
        
        // Convert single location to list format for UI
        final List<Map<String, dynamic>> locations = [];
        
        if (data.isNotEmpty && data['locationID'] != null) {
          locations.add({
            'locationID': data['locationID'] ?? 0,
            'locationName': data['locationName'] ?? '',
            'latitude': (data['latitude'] ?? 0.0).toDouble(),
            'longitude': (data['longitude'] ?? 0.0).toDouble(),
            'radius': (data['radiusInMeters'] ?? 0.0).toDouble(),
            'isActive': data['isActive'] ?? false,
          });
          
          print('✅ Geofence location retrieved successfully: ${data['locationName']}');
        }
        
        return locations;
      } else {
        print('⚠️ Failed to load geofence location. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading geofence location: $e');
      // Return empty list instead of throwing to prevent UI crashes
      return [];
    }
  }

  // Check if within any geofence (for multiple locations)
  static Future<bool> isWithinAnyGeofenceLocation(double userLat, double userLng, List<dynamic> geofenceLocations) async {
    try {
      print('📍 Checking if within any geofence...');
      print('📍 User Location: $userLat, $userLng');
      print('📍 Total geofence locations: ${geofenceLocations.length}');

      // If no geofence locations, try to get the single location
      if (geofenceLocations.isEmpty) {
        print('⚠️ No geofence locations in list, fetching single location...');
        final locations = await getGeofenceLocationsInfo();
        if (locations.isEmpty) {
          print('❌ No geofence locations available at all');
          return false;
        }
        geofenceLocations = locations;
      }

      for (final location in geofenceLocations) {
        if (location['isActive'] == true) {
          final distance = _calculateDistance(
            userLat,
            userLng,
            location['latitude'],
            location['longitude'],
          );
          
          print('📍 Checking location: ${location['locationName']}');
          print('📍 Distance: ${distance.toStringAsFixed(2)}m, Radius: ${location['radius']}m');
          
          if (distance <= location['radius']) {
            print('✅ User is within ${location['locationName']}');
            return true;
          }
        }
      }
      
      print('❌ User is not within any active geofence');
      return false;
    } catch (e) {
      print('❌ Error checking geofence location: $e');
      return false;
    }
  }

  // Get today's attendance status
  static Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final userData = await _getUserDataFromPrefs();
      final employeeID = userData['employeeID']!;
      final companyID = userData['companyID']!;
      final token = userData['token']!;
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      final url = '$_baseUrl/hrm/api/Attendance/GetTodayAttendance/$employeeID/$companyID?date=$today';
      
      print('📡 Getting today attendance: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 30));

      print('📊 Today Attendance Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        
        bool hasCheckedIn = false;
        bool hasCheckedOut = false;
        
        for (final record in data) {
          if (record['checkInTime'] != null) hasCheckedIn = true;
          if (record['checkOutTime'] != null) hasCheckedOut = true;
        }
        
        print('✅ Today attendance status - Checked In: $hasCheckedIn, Checked Out: $hasCheckedOut');
        
        return {
          'hasCheckedIn': hasCheckedIn,
          'hasCheckedOut': hasCheckedOut,
          'records': data,
        };
      } else {
        // Return default values instead of throwing for 404
        print('⚠️ Today attendance not found (404), returning default values');
        return {
          'hasCheckedIn': false,
          'hasCheckedOut': false,
          'records': [],
        };
      }
    } catch (e) {
      print('❌ Error loading today attendance: $e');
      return {
        'hasCheckedIn': false,
        'hasCheckedOut': false,
        'records': [],
      };
    }
  }

  // Mark attendance with current data - FIXED: Handle "already checked out/in" messages
  static Future<Map<String, dynamic>> markAttendanceWithCurrentData({
    required double latitude,
    required double longitude,
    required String attendanceType,
    String source = 'MobileApp',
    String description = '',
  }) async {
    try {
      final userData = await _getUserDataFromPrefs();
      final employeeID = userData['employeeID']!;
      final companyID = userData['companyID']!;
      final token = userData['token']!;
      final createdBy = userData['createdBy']!;
      
      // Get geofence location name
      String geoLocation = 'Unknown Location';
      bool isWithinGeofence = false;
      
      try {
        final geofenceLocations = await getGeofenceLocationsInfo();
        isWithinGeofence = await isWithinAnyGeofenceLocation(latitude, longitude, geofenceLocations);
        if (isWithinGeofence && geofenceLocations.isNotEmpty) {
          geoLocation = geofenceLocations.first['locationName'] ?? 'Office Location';
        } else if (geofenceLocations.isEmpty) {
          // If no geofence is configured, allow attendance from anywhere
          print('⚠️ No geofence configured, allowing attendance from any location');
          geoLocation = 'No Geofence Configured';
          isWithinGeofence = true; // Allow attendance if no geofence
        }
      } catch (e) {
        print('⚠️ Error checking geofence: $e');
        // If geofence check fails, still allow attendance but log the issue
        isWithinGeofence = true;
        geoLocation = 'Geofence Check Failed';
      }

      // Check if within geofence (only if geofence is configured)
      final geofenceLocations = await getGeofenceLocationsInfo();
      if (geofenceLocations.isNotEmpty && !isWithinGeofence) {
        return {
          'isSuccess': false,
          'message': 'You are not within any allowed attendance area',
          'data': null,
          'statusCode': 400,
        };
      }

      // Prepare request body based on attendance type
      final Map<String, dynamic> requestBody;
      
      if (attendanceType == checkInType) {
        // CheckIn request body
        requestBody = {
          "employeeID": employeeID.toString(),
          "companyID": companyID.toString(),
          "latitude": latitude,
          "longitude": longitude,
          "punchTime": DateTime.now().toIso8601String(),
          "ipAddress": await _getIPAddress(),
          "source": source,
          "descIn": description.isNotEmpty ? description : 'Checked In from Mobile App',
          "geoLocationIn": geoLocation,
          "createdBy": createdBy,
        };
      } else {
        // CheckOut request body
        requestBody = {
          "employeeID": employeeID.toString(),
          "companyID": companyID.toString(),
          "latitude": latitude,
          "longitude": longitude,
          "punchTime": DateTime.now().toIso8601String(),
          "ipAddress": await _getIPAddress(),
          "source": source,
          "descOut": description.isNotEmpty ? description : 'Checked Out from Mobile App',
          "geoLocationOut": geoLocation,
          "createdBy": createdBy,
        };
      }

      final String endpoint = attendanceType == checkInType 
          ? 'CheckIn' 
          : 'CheckOut';
          
      final url = '$_baseUrl/hrm/api/Attendance/$endpoint';
      print('📡 Marking attendance ($attendanceType): $url');
      print('📦 Request Body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('📊 Attendance Response Status: ${response.statusCode}');
      print('📊 Attendance Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // FIXED: Check if data contains error message even when isSuccess is true
        final bool isSuccess = responseData['isSuccess'] ?? false;
        String message = responseData['message'] ?? 'Attendance marked successfully';
        final dynamic data = responseData['data'];
        
        // Check if data contains error message (like "Already checked out for today")
        if (data != null && data is String && data.toLowerCase().contains('error')) {
          message = data; // Use the error message from data field
        } else if (data != null && data is String && data.isNotEmpty) {
          // If data has a message but not an error, use it
          message = data;
        }
        
        // Check for specific error patterns in the message
        final String lowerMessage = message.toLowerCase();
        if (lowerMessage.contains('already checked out') || 
            lowerMessage.contains('already checked in') ||
            lowerMessage.contains('error')) {
          return {
            'isSuccess': false, // Treat as failure for these cases
            'message': message,
            'data': data,
            'statusCode': responseData['statusCode'] ?? 200,
          };
        }
        
        return {
          'isSuccess': isSuccess,
          'message': message,
          'data': data,
          'statusCode': responseData['statusCode'] ?? 200,
        };
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'isSuccess': false,
          'message': errorData['message'] ?? 'Bad request',
          'data': null,
          'statusCode': 400,
        };
      } else if (response.statusCode == 401) {
        return {
          'isSuccess': false,
          'message': 'Unauthorized - Please login again',
          'data': null,
          'statusCode': 401,
        };
      } else {
        return {
          'isSuccess': false,
          'message': 'Failed to mark attendance. Status: ${response.statusCode}',
          'data': null,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Unexpected error during attendance: $e');
      return {
        'isSuccess': false,
        'message': 'Failed to mark attendance: $e',
        'data': null,
        'statusCode': 0,
      };
    }
  }

  // Get IP Address (placeholder implementation)
  static Future<String> _getIPAddress() async {
    try {
      return '192.168.1.1';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;

    return distance;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }
}

// Response Models (keep the same)
class GeoFenceResponse {
  final int statusCode;
  final String message;
  final GeoFenceData data;
  final List<dynamic> errors;
  final bool isSuccess;
  final String timestamp;

  GeoFenceResponse({
    required this.statusCode,
    required this.message,
    required this.data,
    required this.errors,
    required this.isSuccess,
    required this.timestamp,
  });

  factory GeoFenceResponse.fromJson(Map<String, dynamic> json) {
    return GeoFenceResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: GeoFenceData.fromJson(json['data'] ?? {}),
      errors: json['errors'] ?? [],
      isSuccess: json['isSuccess'] ?? false,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class GeoFenceData {
  final int locationID;
  final int companyID;
  final String locationName;
  final double latitude;
  final double longitude;
  final double radiusInMeters;
  final bool isActive;
  final String createdOn;
  final String createdBy;
  final String? updatedOn;
  final String? updatedBy;

  GeoFenceData({
    required this.locationID,
    required this.companyID,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    required this.isActive,
    required this.createdOn,
    required this.createdBy,
    this.updatedOn,
    this.updatedBy,
  });

  factory GeoFenceData.fromJson(Map<String, dynamic> json) {
    return GeoFenceData(
      locationID: json['locationID'] ?? 0,
      companyID: json['companyID'] ?? 0,
      locationName: json['locationName'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      radiusInMeters: (json['radiusInMeters'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? false,
      createdOn: json['createdOn'] ?? '',
      createdBy: json['createdBy'] ?? '',
      updatedOn: json['updatedOn'],
      updatedBy: json['updatedBy'],
    );
  }
}

class AttendanceResponse {
  final int statusCode;
  final String message;
  final dynamic data;
  final List<dynamic> errors;
  final bool isSuccess;
  final String timestamp;

  AttendanceResponse({
    required this.statusCode,
    required this.message,
    required this.data,
    required this.errors,
    required this.isSuccess,
    required this.timestamp,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'],
      errors: json['errors'] ?? [],
      isSuccess: json['isSuccess'] ?? false,
      timestamp: json['timestamp'] ?? '',
    );
  }
}