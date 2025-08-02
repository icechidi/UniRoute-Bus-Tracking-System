import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
    );
  }
}
