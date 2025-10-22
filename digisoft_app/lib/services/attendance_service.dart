import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService {
  static const String baseUrl = 'http://stagging.digisoftproducts.com/hrm/api/';

  // Define possible attendance types
  static const String checkInType = 'CheckIn';
  static const String checkOutType = 'CheckOut';

  // Check if automatic time is enabled
  Future<bool> isAutomaticTimeEnabled() async {
    try {
      // Get current device time
      final deviceTime = DateTime.now();
      
      // Get time from a reliable internet source (NTP server or your API)
      final serverTime = await _getServerTime();
      
      if (serverTime == null) {
        throw Exception('Unable to verify time. Please check your internet connection.');
      }

      // Calculate difference in seconds
      final difference = deviceTime.difference(serverTime).inSeconds.abs();
      
      print('⏰ Device Time: $deviceTime');
      print('🌐 Server Time: $serverTime');
      print('⏱️ Time Difference: $difference seconds');

      // Allow max 30 seconds difference (for network delays and processing)
      if (difference > 30) {
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Error checking automatic time: $e');
      rethrow;
    }
  }

  // Get server time from your API or NTP server
  Future<DateTime?> _getServerTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Option 1: Get time from your API
      final url = Uri.parse('${baseUrl}ServerTime'); // You need to create this endpoint
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming API returns: {"serverTime": "2025-10-22T10:30:00.000Z"}
        return DateTime.parse(data['serverTime']);
      }

      // Option 2: If API endpoint doesn't exist, use worldtimeapi.org
      final worldTimeUrl = Uri.parse('http://worldtimeapi.org/api/timezone/Asia/Karachi');
      final worldTimeResponse = await http.get(worldTimeUrl).timeout(Duration(seconds: 10));
      
      if (worldTimeResponse.statusCode == 200) {
        final data = jsonDecode(worldTimeResponse.body);
        return DateTime.parse(data['datetime']);
      }

      return null;
    } catch (e) {
      print('❌ Error getting server time: $e');
      return null;
    }
  }

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
      // IMPORTANT: Validate automatic time is enabled BEFORE marking attendance
      final isTimeAutomatic = await isAutomaticTimeEnabled();
      if (!isTimeAutomatic) {
        throw Exception('Please enable "Automatic date & time" in your phone settings to mark attendance.');
      }

      // First, get all geofence locations for the company
      final List<dynamic> geofenceLocations = await getAllGeofenceLocations(companyID);
      
      // Check if user is within any of the allowed geofence locations
      final bool isWithinAllowedArea = await isWithinAnyGeofenceLocation(
        latitude, 
        longitude, 
        geofenceLocations
      );

      if (!isWithinAllowedArea) {
        throw Exception('You are not within any allowed attendance area. Please move to a designated company location.');
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = Uri.parse('${baseUrl}Attendance/$attendanceType');

      // Use description for both check-in and check-out in descIn field
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
        'descIn': finalDescription,
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

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'isSuccess': responseBody['isSuccess'] ?? false,
          'message': responseBody['message'] ?? '$attendanceType completed',
          'data': responseBody['data'] ?? responseBody,
          'attendanceType': attendanceType,
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 400) {
        throw Exception(responseBody['message'] ?? 'Bad request. Please check your data.');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(responseBody['message'] ?? 'HTTP ${response.statusCode}: ${response.body}');
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

  // Get All GeoFence Locations
  Future<List<dynamic>> getAllGeofenceLocations(int companyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = Uri.parse('${baseUrl}GeoFenceLocation/$companyId');

      print('🌐 Get All GeoFence Locations API URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 GeoFence Locations Response Status: ${response.statusCode}');
      print('📦 GeoFence Locations Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        
        if (responseBody['isSuccess'] == true && responseBody['data'] != null) {
          return responseBody['data'] as List<dynamic>;
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to fetch geofence locations');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        throw Exception(responseBody['message'] ?? 'HTTP ${response.statusCode}: Failed to fetch geofence locations');
      }
    } on http.ClientException catch (e) {
      print('❌ Network error in getAllGeofenceLocations: $e');
      throw Exception('Network error: Please check your internet connection.');
    } on FormatException catch (e) {
      print('❌ Format error in getAllGeofenceLocations: $e');
      throw Exception('Invalid response format from server.');
    } catch (e) {
      print('❌ Error in getAllGeofenceLocations: $e');
      rethrow;
    }
  }

  // Check if user is within any of the geofence locations
  Future<bool> isWithinAnyGeofenceLocation(
    double userLat, 
    double userLon, 
    List<dynamic> geofenceLocations
  ) async {
    try {
      if (geofenceLocations.isEmpty) {
        print('⚠️ No geofence locations found for this company');
        return false;
      }

      for (final location in geofenceLocations) {
        final double locationLat = (location['latitude'] as num).toDouble();
        final double locationLon = (location['longitude'] as num).toDouble();
        final double radius = (location['radiusInMeters'] as num).toDouble();
        final bool isActive = location['isActive'] as bool;

        if (!isActive) {
          continue;
        }

        final double distance = calculateDistance(
          locationLat, 
          locationLon, 
          userLat, 
          userLon
        );

        print('📍 Checking location: ${location['locationName']}');
        print('📍 Distance: ${distance.toStringAsFixed(2)} meters (Allowed: $radius meters)');

        if (distance <= radius) {
          print('✅ User is within allowed location: ${location['locationName']}');
          return true;
        }
      }

      print('❌ User is not within any allowed geofence location');
      return false;
    } catch (e) {
      print('❌ Error checking geofence locations: $e');
      return false;
    }
  }

  // Calculate distance between two coordinates in meters
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

  String getCurrentTimeISOString() {
    final now = DateTime.now();
    return now.toIso8601String();
  }

  // Mark attendance with current data (for both check-in and check-out)
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

  // Get Today's Attendance
  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final employeeID = prefs.getInt('employeeID') ?? 0;

      if (token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      if (employeeID == 0) {
        throw Exception('Employee ID not found. Please login again.');
      }

      final url = Uri.parse('${baseUrl}Attendance/Today?employeeId=$employeeID');

      print('🌐 Get Today Attendance API URL: $url');
      print('🔑 Token Present: ${token.isNotEmpty}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Today Attendance Response Status: ${response.statusCode}');
      print('📦 Today Attendance Response Body: ${response.body}');

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'isSuccess': responseBody['isSuccess'] ?? true,
          'message': responseBody['message'] ?? '',
          'data': responseBody['data'],
          'hasCheckedIn': responseBody['data'] != null && responseBody['data']['checkInTime'] != null,
          'checkInTime': responseBody['data'] != null ? responseBody['data']['checkInTime'] : null,
          'hasCheckedOut': responseBody['data'] != null && responseBody['data']['checkOutTime'] != null,
          'checkOutTime': responseBody['data'] != null ? responseBody['data']['checkOutTime'] : null,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        return {
          'isSuccess': true,
          'message': 'No attendance record found for today',
          'data': null,
          'hasCheckedIn': false,
          'checkInTime': null,
          'hasCheckedOut': false,
          'checkOutTime': null,
        };
      } else {
        throw Exception(responseBody['message'] ?? 'HTTP ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      print('❌ Network error in getTodayAttendance: $e');
      throw Exception('Network error: Please check your internet connection.');
    } on FormatException catch (e) {
      print('❌ Format error in getTodayAttendance: $e');
      throw Exception('Invalid response format from server.');
    } catch (e) {
      print('❌ Error in getTodayAttendance: $e');
      rethrow;
    }
  }

  // Get all geofence locations info for current company
  Future<List<Map<String, dynamic>>> getGeofenceLocationsInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyID = prefs.getInt('companyID') ?? 0;

      if (companyID == 0) {
        throw Exception('Company ID not found. Please login again.');
      }

      final List<dynamic> locations = await getAllGeofenceLocations(companyID);
      
      return locations.map((location) {
        return {
          'locationID': location['locationID'],
          'locationName': location['locationName'],
          'latitude': location['latitude'],
          'longitude': location['longitude'],
          'radius': location['radiusInMeters'],
          'isActive': location['isActive'],
          'address': location['locationName'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting geofence locations info: $e');
      rethrow;
    }
  }
}