import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _attendanceMarked = false;
  String? _errorMessage;
  Position? _currentPosition;
  String _statusMessage = "Ready to mark attendance";
  final List<AttendanceRecord> _attendanceHistory = [];

  bool get isLoading => _isLoading;
  bool get attendanceMarked => _attendanceMarked;
  String? get errorMessage => _errorMessage;
  Position? get currentPosition => _currentPosition;
  String get statusMessage => _statusMessage;
  String get attendanceStatus => _statusMessage;
  List<AttendanceRecord> get attendanceHistory => _attendanceHistory;

  // Office location coordinates
  double get officeLat => 24.895015;
  double get officeLng => 67.072207;
  double get allowedRadius => 20000.0;

  Future<void> loadTodayAttendanceStatus() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Check if attendance already marked today
    final todayAttendance = _attendanceHistory.where((record) => record.date == today).toList();
    
    _attendanceMarked = todayAttendance.isNotEmpty;
    _statusMessage = _attendanceMarked 
        ? "Attendance already marked today at ${todayAttendance.first.time}" 
        : "Ready to mark attendance";
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    _statusMessage = error ?? "Ready to mark attendance";
    notifyListeners();
  }

  void _setStatus(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  void _setAttendanceMarked(bool marked) {
    _attendanceMarked = marked;
    notifyListeners();
  }

  Future<bool> checkLocationServices() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setError("Location services are disabled");
      return false;
    }
    return true;
  }

  Future<bool> checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setError('Location permission denied. Please enable in app settings.');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _setError('Location permission permanently denied. Please enable in app settings.');
      return false;
    }
    
    return true;
  }

  Future<void> checkAndMarkAttendance(BuildContext context) async {
    if (_attendanceMarked) {
      _setError("Attendance already marked for today");
      return;
    }
    
    _setLoading(true);
    _setError(null);
    _setStatus("Checking location services...");
    
    try {
      // Check location service
      bool serviceEnabled = await checkLocationServices();
      if (!serviceEnabled) {
        _setLoading(false);
        return;
      }

      _setStatus("Checking permissions...");
      
      // Check location permission
      bool hasPermission = await checkLocationPermissions();
      if (!hasPermission) {
        _setLoading(false);
        return;
      }

      _setStatus("Getting your current location...");
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 30));
      
      _currentPosition = position;

      // Calculate distance to office
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        officeLat,
        officeLng,
      );

      _setStatus("Checking location... (${distance.toStringAsFixed(0)}m from office)");

      if (distance > allowedRadius) {
        _setLoading(false);
        _setError('You are ${distance.toStringAsFixed(0)}m away from office. Must be within ${allowedRadius.toStringAsFixed(0)}m.');
        return;
      }

      _setStatus("Marking attendance...");
      
      // Mark attendance locally
      await _markAttendanceLocally(position.latitude, position.longitude);
      _setAttendanceMarked(true);
      _setError(null);
      _setStatus("Attendance marked successfully!");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully!'), 
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _setError('Failed to mark attendance: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _markAttendanceLocally(double lat, double lon) async {
    final now = DateTime.now();
    final record = AttendanceRecord(
      date: now.toIso8601String().split('T')[0],
      time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      latitude: lat,
      longitude: lon,
      timestamp: now,
    );
    
    _attendanceHistory.insert(0, record);
    _attendanceMarked = true;
    notifyListeners();
  }

  void resetAttendance() {
    _attendanceMarked = false;
    _errorMessage = null;
    _currentPosition = null;
    _statusMessage = "Ready to mark attendance";
    notifyListeners();
  }

  void clearHistory() {
    _attendanceHistory.clear();
    _attendanceMarked = false;
    _statusMessage = "Ready to mark attendance";
    notifyListeners();
  }
}

class AttendanceRecord {
  final String date;
  final String time;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  AttendanceRecord({
    required this.date,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}