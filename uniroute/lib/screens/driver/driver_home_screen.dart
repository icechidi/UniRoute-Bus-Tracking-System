import 'package:flutter/material.dart';
import 'driver_profile_page.dart';
import 'route_selection_page.dart';
import 'pre_trip_page.dart';
import 'active_trip_page.dart';
import 'bus_selection_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../student/map_screen.dart';

enum BusPage { route, preTrip, activeTrip }

class DriverHomeScreen extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic> driver;

  const DriverHomeScreen({
    super.key,
    this.initialIndex = 0,
    required this.driver,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late int _selectedIndex;
  late BusPage _busPage;
  late BusPage _previousPage;
  String? selectedRoute;
  String? selectedTime;
  String? selectedBusId;

  StreamSubscription<Position>? _locationStream;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _busPage = BusPage.route;
    _previousPage = _busPage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('👤 Driver object at init: ${widget.driver}');
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      if (index == 1) _previousPage = _busPage;
      _selectedIndex = index;
    });
  }

  String _formatTime(dynamic time) {
    if (time is TimeOfDay) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return DateFormat('HH:mm').format(dt);
    } else if (time is DateTime) {
      return DateFormat('HH:mm').format(time);
    } else if (time is String && time.isNotEmpty) {
      return time;
    } else {
      return DateFormat('HH:mm').format(DateTime.now());
    }
  }

  void _goToPreTrip(String route, dynamic time) {
    final formattedTime = _formatTime(time);

    setState(() {
      selectedRoute = route;
      selectedTime = formattedTime;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusSelectionPage(
          onBusSelected: (busId) {
            if (busId.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No bus selected.')),
              );
              return;
            }
            setState(() {
              selectedBusId = busId.toString();
              _busPage = BusPage.preTrip;
            });
            Navigator.pop(context);
          },
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _startSendingLocation() {
    _locationStream?.cancel();
    if (selectedBusId == null) return;

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      final timestamp = DateTime.now().toIso8601String();
      final driverId = _resolveDriverId();

      if (driverId == null) return;

      try {
        final url = Uri.parse('http://172.55.4.160:3000/api/trips/update-location');
        final body = jsonEncode({
          'bus_id': selectedBusId,
          'driver_id': driverId,
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': timestamp,
        });

        final response = await http.post(
          url,
          body: body,
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode != 200) {
          print("⚠️ Location update failed: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        print("❌ Error sending location to backend: $e");
      }
    });
  }

  void _stopSendingLocation() {
    _locationStream?.cancel();
  }

  String? _resolveDriverId() {
    final rawDriver = widget.driver;
    return (rawDriver['id'] ??
            rawDriver['driverId'] ??
            rawDriver['driver_id'] ??
            rawDriver['uid'] ??
            rawDriver['userId'] ??
            rawDriver['user_id'])
        ?.toString();
  }

  Future<void> _goToActiveTrip() async {
    if (selectedRoute == null ||
        selectedTime == null ||
        selectedBusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select a route, time, and bus before starting the trip.')),
      );
      return;
    }

    final driverId = _resolveDriverId();
    if (driverId == null || driverId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver ID missing — cannot start trip.')),
      );
      return;
    }

    // ✅ Capture current location right before starting trip
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("⚠️ Could not get current location: $e");
    }

    await startTripOnBackend(
      selectedRoute!,
      selectedTime!,
      selectedBusId!,
      driverId,
      position?.latitude,
      position?.longitude,
    );

    _startSendingLocation();

    setState(() {
      _busPage = BusPage.activeTrip;
    });
  }

  Future<void> _endTrip() async {
    if (selectedRoute == null ||
        selectedTime == null ||
        selectedBusId == null) {
      return;
    }

    final driverId = _resolveDriverId();
    if (driverId == null || driverId.trim().isEmpty) {
      _stopSendingLocation();
      setState(() {
        selectedRoute = null;
        selectedTime = null;
        selectedBusId = null;
        _busPage = BusPage.route;
      });
      return;
    }

    final endTime = _formatTime(DateTime.now());

    await endTripOnBackend(
        selectedRoute!, selectedTime!, selectedBusId!, driverId, endTime);

    _stopSendingLocation();

    setState(() {
      selectedRoute = null;
      selectedTime = null;
      selectedBusId = null;
      _busPage = BusPage.route;
    });
  }

  // --- Backend API Calls ---
  Future<void> startTripOnBackend(
    String route,
    String time,
    String busId,
    String driverId,
    double? latitude,
    double? longitude,
  ) async {
    final url = Uri.parse('http://172.55.4.160:3000/api/trips/start');
    final body = jsonEncode({
      'route_id': route,
      'start_time': time,
      'bus_id': busId,
      'driver_id': driverId,
      'latitude': latitude,
      'longitude': longitude,
    });

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );
      print('✅ Start trip response: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('❌ Error starting trip: $e');
    }
  }

  Future<void> endTripOnBackend(
      String route, String startTime, String busId, String driverId, String endTime) async {
    final url = Uri.parse('http://172.55.4.160:3000/api/trips/end');
    final body = jsonEncode({
      'route_id': route,
      'start_time': startTime,
      'end_time': endTime,
      'bus_id': busId,
      'driver_id': driverId,
    });

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );
      print('✅ End trip response: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('❌ Error ending trip: $e');
    }
  }
  // --- End Backend API Calls ---

  @override
  void dispose() {
    _locationStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_selectedIndex == 1) {
      bodyContent = DriverProfilePage(
        driver: widget.driver,
        onBack: () {
          setState(() {
            _selectedIndex = 0;
            _busPage = _previousPage;
          });
        },
      );
    } else {
      switch (_busPage) {
        case BusPage.route:
          bodyContent = RouteSelectionPage(
            onContinue: _goToPreTrip,
            onProfileTap: () {
              setState(() {
                _previousPage = _busPage;
                _selectedIndex = 1;
              });
            },
            emergencyButton: _buildEmergencyButton(),
          );
          break;
        case BusPage.preTrip:
          bodyContent = PreTripPage(
            route: selectedRoute ?? 'Unknown route',
            time: selectedTime ?? 'Unknown time',
            busId: selectedBusId ?? 'Unknown bus',
            onStartTrip: _goToActiveTrip,
            onProfileTap: () {
              setState(() {
                _previousPage = _busPage;
                _selectedIndex = 1;
              });
            },
            onBack: () {
              setState(() {
                _busPage = BusPage.route;
              });
            },
          );
          break;
        case BusPage.activeTrip:
          bodyContent = ActiveTripPage(
            route: selectedRoute ?? 'Unknown route',
            time: selectedTime ?? 'Unknown time',
            busId: selectedBusId ?? 'Unknown bus',
            onStopTrip: _endTrip,
            onProfileTap: () {
              setState(() {
                _previousPage = _busPage;
                _selectedIndex = 1;
              });
            },
            onBack: () {
              setState(() {
                _busPage = BusPage.route;
              });
            },
          );
          break;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBody: true,
      body: SafeArea(
        top: false,
        child: Column(
          children: [Expanded(child: bodyContent)],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.directions_bus, 'Bus'),
              _buildNavItem(1, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.grey[800] : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.grey[800]!.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.warning, color: Colors.white),
          label: const Text('Emergency', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Emergency action not implemented yet.')),
            );
          },
        ),
      ),
    );
  }
}
