import 'package:flutter/material.dart';
import 'driver_profile_page.dart';
import 'route_selection_page.dart';
import 'pre_trip_page.dart';
import 'active_trip_page.dart';
import 'bus_selection_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
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
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _busPage = BusPage.route;
    _previousPage = _busPage;

    // DEBUG: print driver object so you can see what keys it has
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('👤 Driver object at init: ${widget.driver}');
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      if (index == 1) {
        _previousPage = _busPage;
      }
      _selectedIndex = index;
    });
  }

  // Show bus selection page after route/time selection
  void _goToPreTrip(String route, String time) {
    setState(() {
      selectedRoute = route;
      selectedTime = time;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusSelectionPage(
          onBusSelected: (busId) {
            // Defensive: busId might be null/empty if DB query failed — handle gracefully
            print('🚌 BusSelectionPage returned busId: $busId');
            if (busId == null || (busId is String && busId.trim().isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'No bus selected (bus id is null). Please try again.'),
                ),
              );
              return;
            }

            setState(() {
              selectedBusId = busId.toString();
              _busPage = BusPage.preTrip;
            });

            // Close BusSelectionPage
            Navigator.pop(context);
          },
          onBack: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _startSendingLocation() {
    _locationStream?.cancel();
    if (selectedBusId == null) return;
    _locationStream =
        Geolocator.getPositionStream().listen((Position position) {
      _dbRef.child('trips/${selectedBusId!}/location').set({
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  void _stopSendingLocation() {
    _locationStream?.cancel();
  }

  /// Resolve driver id from multiple possible keys that your backend might use.
  /// Returns null if no plausible id is found.
  String? _resolveDriverId() {
    final dynamic rawDriver = widget.driver;
    if (rawDriver == null) return null;

    final candidate = rawDriver['id'] ??
        rawDriver['driverId'] ??
        rawDriver['driver_id'] ??
        rawDriver['uid'] ??
        rawDriver['userId'] ??
        rawDriver['user_id'];

    return candidate?.toString();
  }

  Future<void> _goToActiveTrip() async {
    // Defensive checks before using values
    print('▶️ Start Trip pressed. Current selections:');
    print('   route: $selectedRoute');
    print('   time: $selectedTime');
    print('   busId: $selectedBusId');
    print('   driverMap: ${widget.driver}');

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

    final String? driverId = _resolveDriverId();
    if (driverId == null || driverId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver ID missing — cannot start trip.')),
      );
      print('❌ Driver ID is missing in driver map: ${widget.driver}');
      return;
    }

    // Final debug print
    print(
        '➡️ Calling backend startTrip with: route=$selectedRoute, time=$selectedTime, busId=$selectedBusId, driverId=$driverId');

    // Call backend
    await startTripOnBackend(
        selectedRoute!, selectedTime!, selectedBusId!, driverId);

    // Start sending location
    _startSendingLocation();

    setState(() {
      _busPage = BusPage.activeTrip;
    });

    // Navigate to map screen (optional). This is after we updated state to active.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(busId: selectedBusId!),
      ),
    );
  }

  Future<void> _endTrip() async {
    // if nothing selected, nothing to do
    if (selectedRoute == null ||
        selectedTime == null ||
        selectedBusId == null) {
      // Nothing to end, just return
      return;
    }

    final String? driverId = _resolveDriverId();

    if (driverId == null || driverId.trim().isEmpty) {
      print('❌ Driver ID missing when ending trip: ${widget.driver}');
      // still try to stop location and reset UI
      _stopSendingLocation();
      setState(() {
        selectedRoute = null;
        selectedTime = null;
        selectedBusId = null;
        _busPage = BusPage.route;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Driver ID missing — trip local state reset.')),
      );
      return;
    }

    await endTripOnBackend(
        selectedRoute!, selectedTime!, selectedBusId!, driverId);
    _stopSendingLocation();

    setState(() {
      // Reset everything so driver must re-select
      selectedRoute = null;
      selectedTime = null;
      selectedBusId = null;
      _busPage = BusPage.route; // go back to route selection
    });
  }

  // --- Backend API Calls ---
  Future<void> startTripOnBackend(
      String route, String time, String busId, String driverId) async {
    final url = Uri.parse('http://172.55.4.160:3000/api/trips/start');
    final body = jsonEncode({
      'route_id': route,
      'time': time,
      'bus_id': busId,
      'driver_id': driverId,
    });

    try {
      print('🚍 Sending start trip: $body');
      final response = await http.post(
        url,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );
      print('✅ Start trip response: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('❌ Error starting trip: $e');
      // optionally show a SnackBar so user knows start failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to notify server about starting trip.')),
      );
    }
  }

  Future<void> endTripOnBackend(
      String route, String time, String busId, String driverId) async {
    final url = Uri.parse('http://172.55.4.160:3000/api/trips/end');
    final body = jsonEncode({
      'route': route,
      'time': time,
      'busId': busId,
      'driverId': driverId,
    });

    try {
      final response = await http
          .post(url, body: body, headers: {'Content-Type': 'application/json'});
      print('✅ End trip response: ${response.statusCode} - ${response.body}');
      if (response.statusCode != 200) {
        print('Failed to end trip: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server failed to end trip (non-200).')),
        );
      }
    } catch (e) {
      print('Error ending trip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to notify server about ending trip.')),
      );
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
            // provide safe fallbacks so widget build won't throw if values are unexpectedly null
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
          children: [
            Expanded(child: bodyContent),
          ],
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

  // Emergency button widget
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
            // TODO: Implement emergency action
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
