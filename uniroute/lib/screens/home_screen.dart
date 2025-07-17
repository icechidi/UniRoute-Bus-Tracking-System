import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Completer<GoogleMapController> _controller = Completer();

  // Lefkoşa, North Cyprus Longitude and Latitude
  static const LatLng _lefkoshaLatLng = LatLng(35.1856, 33.3823);
// Initial camera position for the map
  static const CameraPosition _kLefkosha = CameraPosition(
    target: _lefkoshaLatLng,
    zoom: 16.0,
    tilt: 45,
  );

  Marker? _userMarker;

  @override
  void initState() {
    super.initState();
  }
// Handle map creation and user location
  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
    await _handleLocation();
  }
// Handle user location and add marker
  Future<void> _handleLocation() async {
    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition();
    final LatLng userLatLng = LatLng(position.latitude, position.longitude);

    // Add marker to user's current location and move camera if within 20km radius of Lefkoşa
    setState(() {
      _userMarker = Marker(
        markerId: const MarkerId("user"),
        position: userLatLng,
        infoWindow: const InfoWindow(title: "Your Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });

    // Move camera only if within 20km radius of Lefkoşa
    final double distance = Geolocator.distanceBetween(
      _lefkoshaLatLng.latitude,
      _lefkoshaLatLng.longitude,
      userLatLng.latitude,
      userLatLng.longitude,
    );

    if (distance <= 20000) {
      final GoogleMapController mapController = await _controller.future;
      mapController.animateCamera(CameraUpdate.newLatLng(userLatLng));
    }
  }
// Check and request location permission
  Future<bool> _checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }
// Build the UI with Google Map
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Route App'),
        centerTitle: true,
      ),
      body: GoogleMap(
        initialCameraPosition: _kLefkosha,
        mapType: MapType.hybrid,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        onMapCreated: _onMapCreated,
        markers: {
          Marker(
            markerId: const MarkerId("lefkosha"),
            position: _lefkoshaLatLng,
            infoWindow: const InfoWindow(title: "Lefkoşa, North Cyprus"),
          ),
          if (_userMarker != null) _userMarker!,
        },
      ),
    );
  }
}
