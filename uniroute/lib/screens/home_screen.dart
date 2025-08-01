<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'schedule_screen.dart'; // Create this if needed
import 'settings_screen.dart'; // Profile/settings
=======
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
>>>>>>> main

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
<<<<<<< HEAD
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(),
    const ScheduleScreen(), // Replace with your screen
    const SettingsScreen(),
  ];
=======
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng _lefkoshaLatLng = LatLng(35.1856, 33.3823);

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _lefkoshaLatLng,
    zoom: 16,
    tilt: 45,
  );
  

  Marker? _userMarker;

//Adding comments to Overide
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getUserLocation());
  }

  Future<void> _getUserLocation() async {
    bool permissionGranted = await _handlePermissions();
    if (!permissionGranted) return;

    Position position = await Geolocator.getCurrentPosition();
    final userLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _userMarker = Marker(
        markerId: const MarkerId('user'),
        position: userLatLng,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(userLatLng));
  }

  Future<bool> _handlePermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
>>>>>>> main

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor:
          Colors.grey[100], // Add background color to see the floating effect
      extendBody:
          true, // This allows the body to extend behind the navigation bar
      body: _screens[_currentIndex],
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
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.location_on, 'Map'),
              _buildNavItem(1, Icons.schedule, 'Schedule'),
              _buildNavItem(2, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
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
=======
      appBar: AppBar(
        title: const Text('Bus Route App'),
        centerTitle: true,
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        mapType: MapType.hybrid,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        onMapCreated: (controller) => _controller.complete(controller),
        markers: {
          Marker(
            markerId: const MarkerId("center"),
            position: _lefkoshaLatLng,
            infoWindow: const InfoWindow(title: "Lefkoşa, North Cyprus"),
          ),
          if (_userMarker != null) _userMarker!,
        },
>>>>>>> main
      ),
    );
  }
}
