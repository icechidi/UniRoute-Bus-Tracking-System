import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_mode_notifier.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  LatLng? _userLocation;

  // New Route1 stops
  final List<LatLng> stops = [
    LatLng(35.21135, 33.23725), // Start
    LatLng(35.209353, 33.298842), // Stop 1
    LatLng(35.208512, 33.308036), // Stop 2
    LatLng(35.208556, 33.317564), // Stop 3
    LatLng(35.212308, 33.334901), // Stop 4
    LatLng(35.210671, 33.343197), // Stop 5
    LatLng(35.211521, 33.374968), // Stop 6
    LatLng(35.202980, 33.374271), // Stop 7
    LatLng(35.202084, 33.367372), // Stop 8
    LatLng(35.199425, 33.367691), // Stop 9
    LatLng(35.194987, 33.367788), // Stop 10
    LatLng(35.187861, 33.365988), // Stop 11
    LatLng(35.182547, 33.362858), // Stop 12
    LatLng(35.185916, 33.357370), // Stop 13
    LatLng(35.190649, 33.352094), // Stop 14
    LatLng(35.193637, 33.348795), // Stop 15
    LatLng(35.197523, 33.344431), // Stop 16
    LatLng(35.199901, 33.340647), // Stop 17
    LatLng(35.205060, 33.330312), // Stop 18
    LatLng(35.208367, 33.317665), // Stop 19
    LatLng(35.208012, 33.312607), // Stop 20
    LatLng(35.208310, 33.307022), // Stop 21
    LatLng(35.211037, 33.238218), // Stop 22 (End)
  ];

  List<LatLng> routePoints = [];

  // OpenRouteService API key
  static const String _orsApiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImY2ZWNjNWQ3NDE0ZTRlNjliMDljNWVkMmE3ZGI1ZTYxIiwiaCI6Im11cm11cjY0In0=';

  @override
  void initState() {
    super.initState();
    _setupLocationTracking();
    _fetchRouteFromORS();
  }

  Future<void> _setupLocationTracking() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final initialLocation = await _location.getLocation();
    setState(() {
      _userLocation = LatLng(
        initialLocation.latitude ?? stops.first.latitude,
        initialLocation.longitude ?? stops.first.longitude,
      );
    });

    _location.onLocationChanged.listen((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _userLocation =
              LatLng(locationData.latitude!, locationData.longitude!);
        });
      }
    });
  }

  Future<void> _fetchRouteFromORS() async {
    final coords = stops.map((p) => [p.longitude, p.latitude]).toList();

    final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car/geojson');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': _orsApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'coordinates': coords}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final geometry = data['features'][0]['geometry'];
        final coordsList = geometry['coordinates'] as List<dynamic>;

        setState(() {
          routePoints = coordsList
              .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
              .toList();
        });
      } else {
        debugPrint(
            'Failed to fetch route: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  void _onTapMap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _userLocation = latlng;
    });
  }

  Future<void> _saveLocationToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userLocation == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await docRef.set({
      'location': {
        'lat': _userLocation!.latitude,
        'lng': _userLocation!.longitude,
      },
      'location_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location saved successfully',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    }
  }

  void _centerOnRoute() {
    if (stops.isNotEmpty) {
      _mapController.move(stops.first, 12.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModeNotifier>(
      builder: (context, themeNotifier, child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black;
        final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
        final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

        // Check if we're on a large screen (web/tablet)
        final isLargeScreen = MediaQuery.of(context).size.width > 768;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: isLargeScreen
              ? _buildWebLayout(context, textColor, cardColor, borderColor)
              : _buildMobileLayout(
                  context, textColor, cardColor, borderColor, isDarkMode),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, Color textColor,
      Color? cardColor, Color? borderColor, bool isDarkMode) {
    return Stack(
      children: [
        // Full screen map
        _buildMapWidget(),

        // Top gradient overlay for better text visibility
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDarkMode ? Colors.black : Colors.white).withOpacity(0.8),
                  (isDarkMode ? Colors.black : Colors.white).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // Custom app bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: cardColor?.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: textColor,
                      size: 20,
                    ),
                  ),
                ),

                const Spacer(),

                // Title
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardColor?.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Bus Route Map',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),

                const Spacer(),

                // Profile avatar
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cardColor?.withOpacity(0.9),
                      ),
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom info panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route info header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.purple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Route Information',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '${stops.length} stops total',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMobileStatCard(
                              Icons.location_pin,
                              'Start',
                              'Stop 0',
                              Colors.green,
                              textColor,
                              cardColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMobileStatCard(
                              Icons.flag,
                              'End',
                              'Stop ${stops.length - 1}',
                              Colors.red,
                              textColor,
                              cardColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMobileStatCard(
                              Icons.route,
                              'Points',
                              '${routePoints.length}',
                              Colors.purple,
                              textColor,
                              cardColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildMobileActionButton(
                              Icons.my_location,
                              'My Location',
                              Colors.blue,
                              _centerOnUserLocation,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMobileActionButton(
                              Icons.route,
                              'View Route',
                              Colors.purple,
                              _centerOnRoute,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatCard(IconData icon, String label, String value,
      Color iconColor, Color textColor, Color? cardColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: textColor.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context, Color textColor,
      Color? cardColor, Color? borderColor) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with full width
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildWebHeader(textColor),
            ),
            const SizedBox(height: 24),

            // Main content area - full width
            Container(
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map takes up most of the width
                  Expanded(
                    flex: 4,
                    child: Card(
                      color: cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: borderColor!, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 700,
                          child: _buildMapWidget(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Side panel - smaller width
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildWebRouteInfoCard(
                            context, textColor, cardColor, borderColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons - full width
            if (_userLocation != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildWebActionButtons(context, textColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHeader(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Map',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your location and view bus routes',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildWebRouteInfoCard(BuildContext context, Color textColor,
      Color? cardColor, Color? borderColor) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildRouteInfo(
              Icons.directions_bus,
              'Total Stops',
              '${stops.length}',
              textColor,
            ),
            const SizedBox(height: 12),
            _buildRouteInfo(
              Icons.route,
              'Route Points',
              '${routePoints.length}',
              textColor,
            ),
            const SizedBox(height: 12),
            _buildRouteInfo(
              Icons.location_pin,
              'Start Point',
              'Stop 0',
              textColor,
            ),
            const SizedBox(height: 12),
            _buildRouteInfo(
              Icons.flag,
              'End Point',
              'Stop ${stops.length - 1}',
              textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(
      IconData icon, String label, String value, Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: textColor, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebActionButtons(BuildContext context, Color textColor) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(
              'Back',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(color: textColor.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveLocationToFirestore,
            icon: const Icon(Icons.save, size: 18),
            label: Text(
              'Save Location',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapWidget() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userLocation ?? stops.first,
        initialZoom: 12.5,
        onTap: _onTapMap,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.app',
        ),
        if (routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: Colors.purple,
                strokeWidth: 5,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Markers for stops
            ...stops.asMap().entries.map((entry) {
              final idx = entry.key;
              final point = entry.value;

              return Marker(
                point: point,
                width: 40,
                height: 40,
                child: Tooltip(
                  message: idx == 0 ? "Start" : "Stop $idx",
                  child: Icon(
                    idx == 0 ? Icons.location_pin : Icons.place,
                    color: idx == 0 ? Colors.green : Colors.red,
                    size: 36,
                  ),
                ),
              );
            }),
            // Marker for user location
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
