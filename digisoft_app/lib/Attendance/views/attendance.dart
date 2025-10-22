import 'dart:async';
import 'package:digisoft_app/services/attendance_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceWithMapScreen extends StatefulWidget {
  @override
  _AttendanceWithMapScreenState createState() => _AttendanceWithMapScreenState();
}

class _AttendanceWithMapScreenState extends State<AttendanceWithMapScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  late GoogleMapController _mapController;
  bool _isLoading = false;
  bool _isWithinRadius = false;
  Position? _currentPosition;
  String _selectedType = AttendanceService.checkInType;
  String _currentTime = '';
  String _shiftInfo = 'General Shift';
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _setupMapCircles();
    
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

  void _setupMapCircles() {
    final allowedLocation = _attendanceService.getAllowedLocationInfo();
    
    _circles = {
      Circle(
        circleId: CircleId('allowed_area'),
        center: LatLng(allowedLocation['latitude'], allowedLocation['longitude']),
        radius: allowedLocation['radius'],
        fillColor: Colors.green.withOpacity(0.3),
        strokeColor: Colors.green,
        strokeWidth: 2,
      ),
    };

    _markers = {
      Marker(
        markerId: MarkerId('allowed_location'),
        position: LatLng(allowedLocation['latitude'], allowedLocation['longitude']),
        infoWindow: InfoWindow(
          title: 'Attendance Area',
          snippet: '20 meters radius',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enable location services'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permissions are denied'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permissions are permanently denied. Please enable them in app settings.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
        _checkIfWithinRadius(position);
      });

      // Move camera to show both user location and allowed area
      if (_mapController != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            _getBounds(position),
            50.0,
          ),
        );
      }

      // Add user marker
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('user_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  LatLngBounds _getBounds(Position userPosition) {
    final allowedLocation = _attendanceService.getAllowedLocationInfo();
    final southwest = LatLng(
      userPosition.latitude < allowedLocation['latitude'] 
          ? userPosition.latitude 
          : allowedLocation['latitude'],
      userPosition.longitude < allowedLocation['longitude'] 
          ? userPosition.longitude 
          : allowedLocation['longitude'],
    );
    final northeast = LatLng(
      userPosition.latitude > allowedLocation['latitude'] 
          ? userPosition.latitude 
          : allowedLocation['latitude'],
      userPosition.longitude > allowedLocation['longitude'] 
          ? userPosition.longitude 
          : allowedLocation['longitude'],
    );
    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  void _checkIfWithinRadius(Position position) {
    final allowedLocation = _attendanceService.getAllowedLocationInfo();
    final distance = _attendanceService.calculateDistance(
      allowedLocation['latitude'],
      allowedLocation['longitude'],
      position.latitude,
      position.longitude,
    );
    
    setState(() {
      _isWithinRadius = distance <= allowedLocation['radius'];
    });
  }

  Future<void> _markAttendance() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get your current location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isWithinRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are not within the allowed attendance area'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _attendanceService.markAttendanceWithCurrentData(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        attendanceType: _selectedType,
        description: _selectedType == AttendanceService.checkInType 
            ? 'Office Check In' 
            : 'Office Check Out',
      );

      setState(() {
        _isLoading = false;
      });

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedType == AttendanceService.checkInType ? 'Check In' : 'Check Out'} successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to mark attendance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      body: Column(
        children: [
          // Header Section - Simplified
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
                      'TIME',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _currentTime,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Shift',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _shiftInfo,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map Section - Takes most of the screen
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _attendanceService.getAllowedLocationInfo()['latitude'],
                      _attendanceService.getAllowedLocationInfo()['longitude'],
                    ),
                    zoom: 16,
                  ),
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  mapToolbarEnabled: true,
                ),

                // Location Status Overlay
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isWithinRadius ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isWithinRadius ? Icons.check_circle : Icons.warning,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isWithinRadius 
                                ? 'Within attendance area ✓'
                                : 'Move to designated area (20m radius)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Refresh Location Button
                Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    mini: true,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.my_location, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Control Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Attendance Type Selection
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTypeButton(AttendanceService.checkInType, 'CHECK IN'),
                     // _buildTypeButton(AttendanceService.checkOutType, 'CHECK OUT'),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Main Action Button
                GestureDetector(
                  onTap: _isWithinRadius && !_isLoading ? _markAttendance : null,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _isWithinRadius 
                          ? (_selectedType == AttendanceService.checkInType ? Colors.green : Colors.blue)
                          : Colors.grey[400],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isWithinRadius ? [
                        BoxShadow(
                          color: (_selectedType == AttendanceService.checkInType ? Colors.green : Colors.blue).withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Touch to ${_selectedType == AttendanceService.checkInType ? 'CHECK IN' : 'CHECK OUT'}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
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

  Widget _buildTypeButton(String type, String label) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? (type == AttendanceService.checkInType ? Colors.green : Colors.blue)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}


// import 'dart:async';

// import 'package:digisoft_app/services/attendance_service.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';

// class AttendanceWithMapScreen extends StatefulWidget {
//   @override
//   _AttendanceWithMapScreenState createState() => _AttendanceWithMapScreenState();
// }

// class _AttendanceWithMapScreenState extends State<AttendanceWithMapScreen> {
//   final AttendanceService _attendanceService = AttendanceService();
//   late GoogleMapController _mapController;
//   bool _isLoading = false;
//   bool _isCheckingAttendance = false;
//   bool _isWithinRadius = false;
//   bool _hasCheckedIn = false;
//   Position? _currentPosition;
//   String _currentTime = '';
//   String _shiftInfo = 'General Shift';
//   String _attendanceMessage = '';
//   Set<Circle> _circles = {};
//   Set<Marker> _markers = {};

//   @override
//   void initState() {
//     super.initState();
//     _updateCurrentTime();
//     _setupMapCircles();
//     _checkTodayAttendance();
    
//     // Update time every minute
//     Timer.periodic(Duration(minutes: 1), (timer) {
//       _updateCurrentTime();
//     });
//   }

//   void _updateCurrentTime() {
//     final now = DateTime.now();
//     setState(() {
//       _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
//     });
//   }

//   void _setupMapCircles() {
//     final allowedLocation = _attendanceService.getAllowedLocationInfo();
    
//     _circles = {
//       Circle(
//         circleId: CircleId('allowed_area'),
//         center: LatLng(allowedLocation['latitude'], allowedLocation['longitude']),
//         radius: allowedLocation['radius'],
//         fillColor: Colors.green.withOpacity(0.3),
//         strokeColor: Colors.green,
//         strokeWidth: 2,
//       ),
//     };

//     _markers = {
//       Marker(
//         markerId: MarkerId('allowed_location'),
//         position: LatLng(allowedLocation['latitude'], allowedLocation['longitude']),
//         infoWindow: InfoWindow(
//           title: 'Attendance Area',
//           snippet: '20 meters radius',
//         ),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ),
//     };
//   }

//   Future<void> _checkTodayAttendance() async {
//     setState(() {
//       _isCheckingAttendance = true;
//     });

//     try {
//       final attendanceData = await _attendanceService.getTodayAttendance();
      
//       setState(() {
//         _hasCheckedIn = attendanceData['hasCheckedIn'] ?? false;
//         _attendanceMessage = attendanceData['message'] ?? '';
        
//         if (_hasCheckedIn) {
//           final checkInTime = attendanceData['checkInTime'];
//           if (checkInTime != null) {
//             // Format the check-in time for display
//             final dateTime = DateTime.parse(checkInTime);
//             final formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
//             _attendanceMessage = 'Already checked in at $formattedTime';
//           }
//         }
//       });
//     } catch (e) {
//       print('Error checking today attendance: $e');
//     } finally {
//       setState(() {
//         _isCheckingAttendance = false;
//       });
//     }
//   }

//   Future<void> _getCurrentLocation() async {
//     try {
//       // Check if location service is enabled
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Please enable location services'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//         return;
//       }

//       // Check location permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Location permissions are denied'),
//               backgroundColor: Colors.red,
//             ),
//           );
//           return;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Location permissions are permanently denied. Please enable them in app settings.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }

//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
      
//       setState(() {
//         _currentPosition = position;
//         _checkIfWithinRadius(position);
//       });

//       // Move camera to show both user location and allowed area
//       if (_mapController != null) {
//         _mapController.animateCamera(
//           CameraUpdate.newLatLngBounds(
//             _getBounds(position),
//             50.0,
//           ),
//         );
//       }

//       // Add user marker
//       setState(() {
//         _markers.add(
//           Marker(
//             markerId: MarkerId('user_location'),
//             position: LatLng(position.latitude, position.longitude),
//             infoWindow: InfoWindow(title: 'Your Location'),
//             icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//           ),
//         );
//       });
//     } catch (e) {
//       print('Error getting location: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error getting location: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   LatLngBounds _getBounds(Position userPosition) {
//     final allowedLocation = _attendanceService.getAllowedLocationInfo();
//     final southwest = LatLng(
//       userPosition.latitude < allowedLocation['latitude'] 
//           ? userPosition.latitude 
//           : allowedLocation['latitude'],
//       userPosition.longitude < allowedLocation['longitude'] 
//           ? userPosition.longitude 
//           : allowedLocation['longitude'],
//     );
//     final northeast = LatLng(
//       userPosition.latitude > allowedLocation['latitude'] 
//           ? userPosition.latitude 
//           : allowedLocation['latitude'],
//       userPosition.longitude > allowedLocation['longitude'] 
//           ? userPosition.longitude 
//           : allowedLocation['longitude'],
//     );
//     return LatLngBounds(southwest: southwest, northeast: northeast);
//   }

//   void _checkIfWithinRadius(Position position) {
//     final allowedLocation = _attendanceService.getAllowedLocationInfo();
//     final distance = _attendanceService.calculateDistance(
//       allowedLocation['latitude'],
//       allowedLocation['longitude'],
//       position.latitude,
//       position.longitude,
//     );
    
//     setState(() {
//       _isWithinRadius = distance <= allowedLocation['radius'];
//     });
//   }

//   Future<void> _markAttendance() async {
//     if (_hasCheckedIn) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(_attendanceMessage),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     if (_currentPosition == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Unable to get your current location'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     if (!_isWithinRadius) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('You are not within the allowed attendance area'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final result = await _attendanceService.markAttendanceWithCurrentData(
//         latitude: _currentPosition!.latitude,
//         longitude: _currentPosition!.longitude,
//         description: 'Office Check In',
//       );

//       setState(() {
//         _isLoading = false;
//       });

//       if (result['isSuccess'] == true) {
//         setState(() {
//           _hasCheckedIn = true;
//           _attendanceMessage = 'Checked in successfully at $_currentTime';
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Check In successful!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(result['message'] ?? 'Failed to mark attendance'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     setState(() {
//       _mapController = controller;
//     });
//     // Get location after map is created
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _getCurrentLocation();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           // Header Section - Simplified
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 10,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'TIME',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       _currentTime,
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       'Shift',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       _shiftInfo,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.blue[700],
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Attendance Status
//           if (_hasCheckedIn || _attendanceMessage.isNotEmpty)
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(12),
//               color: _hasCheckedIn ? Colors.orange[50] : Colors.blue[50],
//               child: Row(
//                 children: [
//                   Icon(
//                     _hasCheckedIn ? Icons.info : Icons.access_time,
//                     color: _hasCheckedIn ? Colors.orange : Colors.blue,
//                     size: 20,
//                   ),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       _attendanceMessage,
//                       style: TextStyle(
//                         color: _hasCheckedIn ? Colors.orange[800] : Colors.blue[800],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   if (_isCheckingAttendance)
//                     SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           _hasCheckedIn ? Colors.orange : Colors.blue
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//           // Map Section - Takes most of the screen
//           Expanded(
//             child: Stack(
//               children: [
//                 GoogleMap(
//                   onMapCreated: _onMapCreated,
//                   initialCameraPosition: CameraPosition(
//                     target: LatLng(
//                       _attendanceService.getAllowedLocationInfo()['latitude'],
//                       _attendanceService.getAllowedLocationInfo()['longitude'],
//                     ),
//                     zoom: 16,
//                   ),
//                   markers: _markers,
//                   circles: _circles,
//                   myLocationEnabled: true,
//                   myLocationButtonEnabled: true,
//                   zoomControlsEnabled: false,
//                   compassEnabled: true,
//                   mapToolbarEnabled: true,
//                 ),

//                 // Location Status Overlay
//                 Positioned(
//                   top: 16,
//                   left: 16,
//                   right: 16,
//                   child: Container(
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: _isWithinRadius ? Colors.green : Colors.orange,
//                       borderRadius: BorderRadius.circular(8),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black26,
//                           blurRadius: 8,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           _isWithinRadius ? Icons.check_circle : Icons.warning,
//                           color: Colors.white,
//                         ),
//                         SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             _isWithinRadius 
//                                 ? 'Within attendance area ✓'
//                                 : 'Move to designated area (20m radius)',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // Refresh Location Button
//                 Positioned(
//                   bottom: 100,
//                   right: 16,
//                   child: FloatingActionButton(
//                     onPressed: _getCurrentLocation,
//                     mini: true,
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.my_location, color: Colors.blue),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Bottom Control Section
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border(top: BorderSide(color: Colors.grey[300]!)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 10,
//                   offset: Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Main Action Button
//                 GestureDetector(
//                   onTap: _hasCheckedIn 
//                       ? null 
//                       : (_isWithinRadius && !_isLoading ? _markAttendance : null),
//                   child: Container(
//                     width: double.infinity,
//                     height: 60,
//                     decoration: BoxDecoration(
//                       color: _hasCheckedIn
//                           ? Colors.grey[400]
//                           : (_isWithinRadius ? Colors.green : Colors.grey[400]),
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: (_isWithinRadius && !_hasCheckedIn) ? [
//                         BoxShadow(
//                           color: Colors.green.withOpacity(0.3),
//                           blurRadius: 10,
//                           offset: Offset(0, 4),
//                         ),
//                       ] : null,
//                     ),
//                     child: Stack(
//                       children: [
//                         Center(
//                           child: _isLoading
//                               ? SizedBox(
//                                   width: 20,
//                                   height: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                   ),
//                                 )
//                               : Text(
//                                   _hasCheckedIn 
//                                       ? 'ALREADY CHECKED IN' 
//                                       : 'TOUCH TO CHECK IN',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }