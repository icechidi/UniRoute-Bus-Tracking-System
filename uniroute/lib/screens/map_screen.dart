import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/location_bottom_sheet.dart';
import '../routes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

/// MapScreen shows real-time user location on a styled Google Map.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Completer to manage GoogleMapController
  final Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController _mapController;

  // Bottom navigation bar index
  int _selectedIndex = 0;

  // Starting coordinates (Lefkoşa)
  static const LatLng _initialLatLng = LatLng(35.1856, 33.3823);

  // Initial camera view (set to reasonable zoom)
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _initialLatLng,
    zoom: 16.0, // Good default for city view
    tilt: 45,
  );

  // Marker to represent user position
  Marker? _userMarker;

  // Used to prevent excessive camera animation
  bool _isCameraMoving = false;

  // Stores the last known location
  LatLng? _lastLocation;

  // Stream to listen for location updates
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLocationStream();
  }

  /// Load and apply custom map styling (optional)
  Future<void> _setMapStyle() async {
    final style = await DefaultAssetBundle.of(context).loadString('assets/map_style.json');
    _mapController.setMapStyle(style);
  }

  /// Start real-time location tracking
  Future<void> _startLocationStream() async {
    bool permissionGranted = await _handlePermissions();
    if (!permissionGranted) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only trigger if user moves ~10m
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        final newLatLng = LatLng(position.latitude, position.longitude);

        // Only update if location changed
        if (_lastLocation == null ||
            _lastLocation!.latitude != newLatLng.latitude ||
            _lastLocation!.longitude != newLatLng.longitude) {
          _updateUserLocation(newLatLng);
        }
      },
    );
  }

  /// Update user's marker and optionally move the camera
  Future<void> _updateUserLocation(LatLng position) async {
    _lastLocation = position;

    // Update marker on map
    setState(() {
      _userMarker = Marker(
        markerId: const MarkerId('user'),
        position: position,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });

    // Smooth camera follow (throttled)
    if (!_isCameraMoving) {
      _isCameraMoving = true;

      final controller = await _controller.future;
      // Animate camera to new location, but keep zoom at current level
      final currentZoom = await controller.getZoomLevel();
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: currentZoom, tilt: 45),
      ));

      Future.delayed(const Duration(milliseconds: 800), () {
        _isCameraMoving = false;
      });
    }
  }

  /// Request and check location permissions
  Future<bool> _handlePermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Zoom in or out on the map
  Future<void> _zoomMap(bool zoomIn) async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomBy(zoomIn ? 1.0 : -1.0));
  }

  /// Handle bottom navigation item taps
  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _showBottomSheet('location');
    } else if (index == 1) {
      Navigator.pushNamed(context, Routes.booking);
    } else if (index == 2) {
      Navigator.pushNamed(context, Routes.profile);
    }
  }

  /// Show modal bottom sheet for location info
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
    _positionStream?.cancel(); // Stop listening to location updates
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌍 Google Map Widget
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(10, 20), // Prevent over-zoom
            markers: {
              // Static marker at the center
              Marker(
                markerId: const MarkerId("center"),
                position: _initialLatLng,
                infoWindow: const InfoWindow(title: "Lefkoşa, North Cyprus"),
              ),
              if (_userMarker != null) _userMarker!,
            },
            onMapCreated: (controller) {
              _mapController = controller;
              _controller.complete(controller);
              _setMapStyle(); // Load map style from JSON
            },
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
            }, // Enable all gestures
          ),

          // 📌 Top App Bar with profile
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Text('Map', style: TextStyle(color: Colors.black)),
              // No profile image
            ),
          ),

          // ➕ Zoom In/Out Buttons
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

      // 🔻 Bottom Navigation Bar
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
