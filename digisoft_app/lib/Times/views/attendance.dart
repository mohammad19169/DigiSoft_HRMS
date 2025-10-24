import 'dart:async';
import 'package:digisoft_app/services/attendance_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceWithMapScreen extends StatefulWidget {
  const AttendanceWithMapScreen({super.key});

  @override
  _AttendanceWithMapScreenState createState() => _AttendanceWithMapScreenState();
}

class _AttendanceWithMapScreenState extends State<AttendanceWithMapScreen> {
  late GoogleMapController _mapController;
  bool _isLoading = false;
  bool _isWithinRadius = false;
  Position? _currentPosition;
  String _selectedType = AttendanceService.checkInType;
  String _currentTime = '';
  final String _shiftInfo = 'General Shift';
  final Set<Circle> _circles = {};
  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _geofenceLocations = [];
  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  bool _hasGeofence = false;

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _loadGeofenceLocations();
    _checkTodayAttendance();
    
    // Update time every minute
    Timer.periodic(Duration(minutes: 1), (timer) {
      _updateCurrentTime();
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _checkTodayAttendance() async {
    try {
      final result = await AttendanceService.getTodayAttendance();
      setState(() {
        _hasCheckedIn = result['hasCheckedIn'] ?? false;
        _hasCheckedOut = result['hasCheckedOut'] ?? false;
        
        // AUTO-SELECT the correct attendance type based on status
        if (_hasCheckedIn && !_hasCheckedOut) {
          _selectedType = AttendanceService.checkOutType; // Auto-select checkout if checked in but not out
        } else {
          _selectedType = AttendanceService.checkInType; // Auto-select checkin if not checked in
        }
      });
    } catch (e) {
      print('Error checking today attendance: $e');
    }
  }

  Future<void> _loadGeofenceLocations() async {
    try {
      final locations = await AttendanceService.getGeofenceLocationsInfo();
      setState(() {
        _geofenceLocations = locations;
        _hasGeofence = locations.isNotEmpty;
      });
      _setupMapCircles();
    } catch (e) {
      print('Error loading geofence locations: $e');
      setState(() {
        _hasGeofence = false;
      });
    }
  }

  void _setupMapCircles() {
    _circles.clear();
    _markers.clear();

    for (int i = 0; i < _geofenceLocations.length; i++) {
      final location = _geofenceLocations[i];
      if (location['isActive'] == true) {
        _circles.add(
          Circle(
            circleId: CircleId('geofence_${location['locationID']}'),
            center: LatLng(location['latitude'], location['longitude']),
            radius: location['radius'],
            fillColor: Colors.green.withOpacity(0.2),
            strokeColor: Colors.green,
            strokeWidth: 2,
          ),
        );

        _markers.add(
          Marker(
            markerId: MarkerId('location_${location['locationID']}'),
            position: LatLng(location['latitude'], location['longitude']),
            infoWindow: InfoWindow(
              title: location['locationName'],
              snippet: '${location['radius']} meters radius',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
    }

    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showAlertDialog('Location Service', 'Please enable location services', false);
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showAlertDialog('Permission Denied', 'Location permissions are denied', false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showAlertDialog('Permission Required', 'Location permissions are permanently denied. Please enable them in app settings.', false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
      });

      // Move camera to show user location
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    
      // Add/Update user marker
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'user_location');
        _markers.add(
          Marker(
            markerId: MarkerId('user_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      // Check if within geofence
      _checkIfWithinAnyGeofence(position);
    } catch (e) {
      print('Error getting location: $e');
      _showAlertDialog('Location Error', 'Error getting location: $e', false);
    }
  }

  Future<void> _checkIfWithinAnyGeofence(Position position) async {
    try {
      if (_geofenceLocations.isEmpty) {
        await _loadGeofenceLocations();
      }

      final isWithin = await AttendanceService.isWithinAnyGeofenceLocation(
        position.latitude,
        position.longitude,
        _geofenceLocations,
      );
      
      print('🔍 UI Check - Position: ${position.latitude}, ${position.longitude}');
      print('🔍 UI Check - Is within radius: $isWithin');
      print('🔍 UI Check - Active geofence locations: ${_geofenceLocations.length}');
      print('🔍 UI Check - Has geofence configured: $_hasGeofence');
      
      setState(() {
        // If no geofence is configured, allow attendance from anywhere
        _isWithinRadius = _hasGeofence ? isWithin : true;
      });
    } catch (e) {
      print('Error checking geofence: $e');
      setState(() {
        _isWithinRadius = !_hasGeofence; // Allow if no geofence configured
      });
    }
  }

  Future<void> _markAttendance() async {
    if (_currentPosition == null) {
      _showAlertDialog('Location Error', 'Unable to get your current location', false);
      return;
    }

    if (!_isWithinRadius) {
      _showAlertDialog('Location Error', 'You are not within any allowed attendance area', false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 Starting attendance marking...');
      print('📍 Current Position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      print('📝 Attendance Type: $_selectedType');
      print('✅ Is Within Radius (UI Check): $_isWithinRadius');
      print('📍 Has Geofence Configured: $_hasGeofence');
      
      final result = await AttendanceService.markAttendanceWithCurrentData(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        attendanceType: _selectedType, // This will now pass checkout when selected
        description: _selectedType == AttendanceService.checkInType 
            ? 'Office Check In' 
            : 'Office Check Out',
      );

      print('✅ Attendance Result: ${result['isSuccess']}');
      print('📨 API Message: ${result['message']}');

      setState(() {
        _isLoading = false;
      });

      // Show the exact API message in alert dialog
      _showAlertDialog(
        result['isSuccess'] == true ? 'SUCCESS' : 'ERROR',
        result['message'] ?? 'Attendance marked',
        result['isSuccess'] == true,
      );

      // Refresh attendance status after successful marking
      if (result['isSuccess'] == true) {
        await _checkTodayAttendance();
      }
    } catch (e) {
      print('❌ Attendance Error: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      // Extract clean error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      
      _showAlertDialog('ERROR', errorMessage, false);
    }
  }

  void _showAlertDialog(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with status
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Message section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    
                    // OK Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSuccess ? Colors.green : Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
    // Get location after map is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          'Mark Attendance',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header Section - REMOVED the "Not Checked In" status button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT TIME',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      _currentTime,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SHIFT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      _shiftInfo,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Simple status indicator without the button
                    // Container(
                    //   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    //   decoration: BoxDecoration(
                    //     color: _getStatusColor().withOpacity(0.1),
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(
                    //       color: _getStatusColor(),
                    //       width: 1,
                    //     ),
                    //   ),
                    //   child: Text(
                    //     _getStatusText(),
                    //     style: TextStyle(
                    //       fontSize: 12,
                    //       fontWeight: FontWeight.bold,
                    //       color: _getStatusColor(),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),

          // Map Section
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(24.8857391, 67.118721), // Default location
                    zoom: 16,
                  ),
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                ),

                // Location Status Overlay
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isWithinRadius 
                            ? [Colors.green[600]!, Colors.green[500]!]
                            : (_hasGeofence ? [Colors.orange[600]!, Colors.orange[500]!] : [Colors.blue[600]!, Colors.blue[500]!]),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isWithinRadius 
                                ? Icons.check_circle 
                                : (_hasGeofence ? Icons.location_off : Icons.location_searching),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _hasGeofence 
                                    ? (_isWithinRadius ? 'WITHIN ATTENDANCE AREA' : 'OUTSIDE ATTENDANCE AREA')
                                    : 'NO GEOFENCE CONFIGURED',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _hasGeofence
                                    ? (_isWithinRadius 
                                        ? 'You can mark your attendance'
                                        : 'Move to allowed attendance area')
                                    : 'Attendance allowed from any location',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Refresh Location Button
                Positioned(
                  bottom: 120,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    elevation: 4,
                    child: Icon(Icons.my_location, size: 24),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Control Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Attendance Type Selection - FIXED: Both buttons are always selectable
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTypeButton(AttendanceService.checkInType, 'CHECK IN', Icons.login),
                      SizedBox(width: 8),
                      _buildTypeButton(AttendanceService.checkOutType, 'CHECK OUT', Icons.logout),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                
                // Main Action Button
                GestureDetector(
                  onTap: (_isWithinRadius || !_hasGeofence) && !_isLoading ? _markAttendance : null,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: (_isWithinRadius || !_hasGeofence) 
                          ? LinearGradient(
                              colors: _selectedType == AttendanceService.checkInType 
                                  ? [Colors.green[600]!, Colors.green[500]!]
                                  : [Colors.orange[600]!, Colors.orange[500]!],
                            )
                          : null,
                      color: !(_isWithinRadius || !_hasGeofence) ? Colors.grey[300] : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: (_isWithinRadius || !_hasGeofence) ? [
                        BoxShadow(
                          color: (_selectedType == AttendanceService.checkInType 
                              ? Colors.green 
                              : Colors.orange).withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _selectedType == AttendanceService.checkInType 
                                      ? Icons.fingerprint 
                                      : Icons.exit_to_app,
                                  color: (_isWithinRadius || !_hasGeofence) ? Colors.white : Colors.grey[500],
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'MARK ${_selectedType == AttendanceService.checkInType ? 'CHECK IN' : 'CHECK OUT'}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: (_isWithinRadius || !_hasGeofence) ? Colors.white : Colors.grey[500],
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, IconData icon) {
    bool isSelected = _selectedType == type;
    
    // FIXED: Both buttons are always enabled and selectable
    bool isEnabled = true;
    
    return Expanded(
      child: GestureDetector(
        onTap: isEnabled ? () {
          setState(() {
            _selectedType = type;
          });
        } : null,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? LinearGradient(
                    colors: type == AttendanceService.checkInType 
                        ? [Colors.green[600]!, Colors.green[500]!]
                        : [Colors.orange[600]!, Colors.orange[500]!],
                  )
                : null,
            color: !isSelected ? Colors.transparent : null,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? null : Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : (isEnabled ? Colors.grey[600] : Colors.grey[400]),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isEnabled ? Colors.grey[600] : Colors.grey[400]),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}