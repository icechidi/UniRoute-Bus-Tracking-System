import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = LatLng(35.325, 33.887);
  LatLng? _userLocation;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  bool _satelliteView = false;

  final TextEditingController _searchController = TextEditingController();
  Stream<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  void _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update if user moves 5 meters
      ),
    );

    _positionStream!.listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = newLocation;
        _currentCenter = newLocation;
      });
      _mapController.move(newLocation, _mapController.camera.zoom);
    });
  }

  Future<void> _searchLocation(String query) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
    final response = await http.get(url, headers: {
      'User-Agent': 'flutter_map_app'
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        setState(() {
          _destination = LatLng(lat, lon);
        });
        _mapController.move(_destination!, 14.0);
        _getRoute();
      }
    }
  }

  Future<void> _getRoute() async {
    if (_userLocation == null || _destination == null) return;

    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${_userLocation!.longitude},${_userLocation!.latitude};${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=geojson');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'];

      List<LatLng> points = coords
          .map<LatLng>((c) => LatLng(c[1], c[0]))
          .toList();

      setState(() {
        _routePoints = points;
      });
    }
  }

  TileLayer get _mapLayer => _satelliteView
      ? TileLayer(
          urlTemplate:
              'https://api.maptiler.com/tiles/satellite-v2/{z}/{x}/{y}.jpg?key=87fgN0EU37KDvIcWNuCs',
          userAgentPackageName: 'com.example.yourapp',
        )
      : TileLayer(
          urlTemplate:
              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.yourapp',
        );

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (_userLocation != null)
        Marker(
          width: 60,
          height: 60,
          point: _userLocation!,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
        ),
      if (_destination != null)
        Marker(
          width: 60,
          height: 60,
          point: _destination!,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        )
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("North Cyprus Map"),
        actions: [
          IconButton(
            icon: Icon(_satelliteView ? Icons.map : Icons.satellite_alt),
            onPressed: () {
              setState(() {
                _satelliteView = !_satelliteView;
              });
            },
            tooltip: 'Toggle Earth View',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search a place...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () =>
                      _searchLocation(_searchController.text.trim()),
                )
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentCenter,
                zoom: 13.0,
              ),
              children: [
                _mapLayer,
                MarkerLayer(markers: markers),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.green,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
