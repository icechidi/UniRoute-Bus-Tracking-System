import 'package:google_maps_flutter/google_maps_flutter.dart';

final Set<Marker> busStopMarkers = {
  Marker(
    markerId: const MarkerId('bus1'),
    position: const LatLng(35.3325, 33.9245),
    infoWindow: const InfoWindow(title: 'Bus Stop 1'),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
  ),
  Marker(
    markerId: const MarkerId('bus2'),
    position: const LatLng(35.3360, 33.9100),
    infoWindow: const InfoWindow(title: 'Bus Stop 2'),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
  ),
  // Add more as needed...
};
