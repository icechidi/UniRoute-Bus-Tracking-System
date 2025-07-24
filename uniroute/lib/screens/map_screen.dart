import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/location_bottom_sheet.dart';
import '../routes.dart';

/// MapScreen shows real-time user location on a Google Map.
/// Includes zoom buttons, AppBar, profile avatar, and bottom navigation.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // Track bottom navigation selection
  int _selectedIndex = 0;

  // Initial coordinates for Lefkoşa
  static const LatLng _initialLatLng = LatLng(35.1856, 33.3823);

  // Initial camera setup
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _initialLatLng,
    zoom: 16,
    tilt: 45,
  );

  // User's marker
  Marker? _userMarker;

  // Used to avoid too frequent camera movements
  bool _isCameraMoving = false;

  // To avoid redundant updates when location doesn't change
  LatLng? _lastLocation;

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLocationStream();
  }

  /// Starts the real-time location stream
  Future<void> _startLocationStream() async {
    bool permissionGranted = await _handlePermissions();
    if (!permissionGranted) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only emit when location changes significantly
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        final newLatLng = LatLng(position.latitude, position.longitude);

        // Only update if different from previous location
        if (_lastLocation == null ||
            _lastLocation!.latitude != newLatLng.latitude ||
            _lastLocation!.longitude != newLatLng.longitude) {
          _updateUserLocation(newLatLng);
        }
      },
    );
  }

  /// Updates user's location marker and optionally moves camera
  Future<void> _updateUserLocation(LatLng position) async {
    _lastLocation = position;

    // Update marker
    setState(() {
      _userMarker = Marker(
        markerId: const MarkerId('user'),
        position: position,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });

    // Move camera, throttled to avoid overloading the map engine
    if (!_isCameraMoving) {
      _isCameraMoving = true;

      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(position));

      // Add short delay to prevent flooding
      Future.delayed(const Duration(milliseconds: 800), () {
        _isCameraMoving = false;
      });
    }
  }

  /// Request location permission
  Future<bool> _handlePermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Zoom map in or out
  Future<void> _zoomMap(bool zoomIn) async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomBy(zoomIn ? 1.0 : -1.0));
  }

  /// Navigation bar logic
  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _showBottomSheet('location');
    } else if (index == 1) {
      Navigator.pushNamed(context, Routes.schedule);
    } else if (index == 2) {
      Navigator.pushNamed(context, Routes.profile);
    }
  }

  /// Show bottom sheet when user selects 'Location'
  void _showBottomSheet(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => LocationBottomSheet(type: type),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // Clean up the stream
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _controller.complete(controller),
            markers: {
              Marker(
                markerId: const MarkerId("center"),
                position: _initialLatLng,
                infoWindow: const InfoWindow(title: "Lefkoşa, North Cyprus"),
              ),
              if (_userMarker != null) _userMarker!,
            },
          ),

          // AppBar (moved up a bit)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Text('Map', style: TextStyle(color: Colors.black)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                    radius: 18,
                  ),
                ),
              ],
            ),
          ),

          // Zoom In/Out Buttons
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () => _zoomMap(true),
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () => _zoomMap(false),
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/location_icon.png', width: 32, height: 32),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/schedule_icon.png', width: 32, height: 32),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/user_icon.png', width: 32, height: 32),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
