import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum MapStyle { standard, satellite }

enum RouteType { route1, route2 }

enum LocationAccuracyLevel { low, medium, high, best }

class RouteData {
  final String name;
  final List<LatLng> stops;
  final Color color;
  final Color markerColor;
  final IconData icon;

  RouteData({
    required this.name,
    required this.stops,
    required this.color,
    required this.markerColor,
    required this.icon,
  });
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  double? _locationAccuracy;
  double? _locationSpeed;
  double? _locationHeading;
  DateTime? _lastLocationUpdate;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLocationServiceEnabled = false;
  bool _hasLocationPermission = false;
  LocationAccuracyLevel _accuracyLevel = LocationAccuracyLevel.high;

  MapStyle _currentMapStyle = MapStyle.satellite;
  bool _showLabels = true;
  RouteType _currentRoute = RouteType.route1;

  // Enhanced location settings
  final Map<LocationAccuracyLevel, LocationSettings> _locationSettings = {
    LocationAccuracyLevel.low: const LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 10,
      timeLimit: Duration(seconds: 10),
    ),
    LocationAccuracyLevel.medium: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 5,
      timeLimit: Duration(seconds: 8),
    ),
    LocationAccuracyLevel.high: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
      timeLimit: Duration(seconds: 5),
    ),
    LocationAccuracyLevel.best: const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 3),
    ),
  };

  // Route definitions with more precise coordinates
  final Map<RouteType, RouteData> routes = {
    RouteType.route1: RouteData(
      name: 'Route 1 - Main Line',
      color: Colors.purple,
      markerColor: Colors.deepPurple,
      icon: Icons.directions_bus,
      stops: [
        const LatLng(35.211350, 33.237250), // Start - Enhanced precision
        const LatLng(35.209353, 33.298842), // Stop 1
        const LatLng(35.208512, 33.308036), // Stop 2
        const LatLng(35.208556, 33.317564), // Stop 3
        const LatLng(35.212308, 33.334901), // Stop 4
        const LatLng(35.210671, 33.343197), // Stop 5
        const LatLng(35.211521, 33.374968), // Stop 6
        const LatLng(35.202980, 33.374271), // Stop 7
        const LatLng(35.202084, 33.367372), // Stop 8
        const LatLng(35.199425, 33.367691), // Stop 9
        const LatLng(35.194987, 33.367788), // Stop 10
        const LatLng(35.187861, 33.365988), // Stop 11
        const LatLng(35.182547, 33.362858), // Stop 12
        const LatLng(35.185916, 33.357370), // Stop 13
        const LatLng(35.190649, 33.352094), // Stop 14
        const LatLng(35.193637, 33.348795), // Stop 15
        const LatLng(35.197523, 33.344431), // Stop 16
        const LatLng(35.199901, 33.340647), // Stop 17
        const LatLng(35.205060, 33.330312), // Stop 18
        const LatLng(35.208367, 33.317665), // Stop 19
        const LatLng(35.208012, 33.312607), // Stop 20
        const LatLng(35.208310, 33.307022), // Stop 21
        const LatLng(35.211037, 33.238218), // Stop 22 (End)
      ],
    ),
    RouteType.route2: RouteData(
      name: 'Route 2 - Express Line',
      color: Colors.orange,
      markerColor: Colors.deepOrange,
      icon: Icons.directions_bus_filled,
      stops: [
        const LatLng(35.211350, 33.237250), // Start - Enhanced precision
        const LatLng(35.209353, 33.298842), // Stop 1
        const LatLng(35.208512, 33.308036), // Stop 2
        const LatLng(35.208556, 33.317564), // Stop 3
        const LatLng(35.212308, 33.334901), // Stop 4
        const LatLng(35.210671, 33.343197), // Stop 5
        const LatLng(35.211521, 33.374968), // Stop 6
        const LatLng(35.202980, 33.374271), // Stop 7
        const LatLng(35.202084, 33.367372), // Stop 8
        const LatLng(35.199425, 33.367691), // Stop 9
        const LatLng(35.194987, 33.367788), // Stop 10
      ],
    ),
  };

  List<LatLng> routePoints = [];

  // OpenRouteService API key
  static const String _orsApiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImY2ZWNjNWQ3NDE0ZTRlNjliMDljNWVkMmE3ZGI1ZTYxIiwiaCI6Im11cm11cjY0In0=';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _fetchRouteFromORS();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  RouteData get currentRouteData => routes[_currentRoute]!;

  String _getMapUrl() {
    switch (_currentMapStyle) {
      case MapStyle.standard:
        return "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
      case MapStyle.satellite:
        return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}";
    }
  }

  List<String> _getSubdomains() {
    switch (_currentMapStyle) {
      case MapStyle.standard:
        return ['a', 'b', 'c'];
      case MapStyle.satellite:
        return [''];
    }
  }

  String _getStyleName(MapStyle style) {
    switch (style) {
      case MapStyle.standard:
        return 'Standard';
      case MapStyle.satellite:
        return 'Satellite';
    }
  }

  IconData _getStyleIcon(MapStyle style) {
    switch (style) {
      case MapStyle.standard:
        return Icons.map;
      case MapStyle.satellite:
        return Icons.satellite_alt;
    }
  }

  String _getAccuracyLevelName(LocationAccuracyLevel level) {
    switch (level) {
      case LocationAccuracyLevel.low:
        return 'Power Saver (~100m)';
      case LocationAccuracyLevel.medium:
        return 'Balanced (~10m)';
      case LocationAccuracyLevel.high:
        return 'High Accuracy (~3m)';
      case LocationAccuracyLevel.best:
        return 'Best (~1m)';
    }
  }

  // Enhanced location initialization with better error handling
  Future<void> _initializeLocation() async {
    try {
      // Check if location service is enabled
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isLocationServiceEnabled) {
        _showLocationDialog(
          'Location Services Disabled',
          'Please enable location services in your device settings for better accuracy.',
          [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _hasLocationPermission = false;
          _showLocationDialog(
            'Location Permission Required',
            'This app needs location access to show your position on the map and provide accurate navigation.',
            [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _initializeLocation();
                },
                child: const Text('Retry'),
              ),
            ],
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _hasLocationPermission = false;
        _showLocationDialog(
          'Location Permission Permanently Denied',
          'Please enable location permission in app settings for the best experience.',
          [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
        return;
      }

      _hasLocationPermission = true;
      await _startLocationTracking();
    } catch (e) {
      debugPrint('Error initializing location: $e');
      _showLocationError('Failed to initialize location services.');
    }
  }

  // Enhanced location tracking with multiple attempts
  Future<void> _startLocationTracking() async {
    if (!_hasLocationPermission || !_isLocationServiceEnabled) return;

    try {
      // Get initial location with retries
      Position? initialPosition = await _getCurrentLocationWithRetry();

      if (initialPosition != null) {
        setState(() {
          _userLocation =
              LatLng(initialPosition.latitude, initialPosition.longitude);
          _locationAccuracy = initialPosition.accuracy;
          _locationSpeed = initialPosition.speed;
          _locationHeading = initialPosition.heading;
          _lastLocationUpdate = DateTime.now();
        });
      }

      // Start continuous location updates
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings[_accuracyLevel]!,
      ).listen(
        (Position position) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
            _locationAccuracy = position.accuracy;
            _locationSpeed = position.speed;
            _locationHeading = position.heading;
            _lastLocationUpdate = DateTime.now();
          });
        },
        onError: (error) {
          debugPrint('Location stream error: $error');
          _showLocationError('Location tracking error. Trying to reconnect...');
          // Attempt to restart location tracking after a delay
          Timer(const Duration(seconds: 5), () => _startLocationTracking());
        },
      );
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      _showLocationError('Failed to start location tracking.');
    }
  }

  // Get current location with multiple attempts and different accuracy levels
  Future<Position?> _getCurrentLocationWithRetry({int maxAttempts = 3}) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        // Use progressively less strict accuracy requirements
        LocationAccuracy accuracy = attempt == 1
            ? LocationAccuracy.best
            : attempt == 2
                ? LocationAccuracy.high
                : LocationAccuracy.medium;

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
          timeLimit: Duration(seconds: 10 + (attempt * 5)),
        );

        debugPrint(
            'Location acquired on attempt $attempt with accuracy: ${position.accuracy}m');
        return position;
      } catch (e) {
        debugPrint('Location attempt $attempt failed: $e');
        if (attempt == maxAttempts) {
          // Try last resort location
          try {
            return await Geolocator.getLastKnownPosition();
          } catch (_) {
            return null;
          }
        }
        // Wait before retrying
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
  }

  void _showLocationDialog(String title, String message, List<Widget> actions) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: actions,
        ),
      );
    }
  }

  void _showLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // Enhanced route fetching
  Future<void> _fetchRouteFromORS() async {
    final coords =
        currentRouteData.stops.map((p) => [p.longitude, p.latitude]).toList();

    final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car/geojson');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': _orsApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'coordinates': coords,
          'preference': 'recommended',
          'geometry_simplify': false,
          'continue_straight': false,
        }),
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
      _locationAccuracy = null; // Clear accuracy since this is manual
      _lastLocationUpdate = DateTime.now();
    });
  }

  void _saveLocation() {
    if (_userLocation == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Location saved: ${_userLocation!.latitude.toStringAsFixed(6)}, ${_userLocation!.longitude.toStringAsFixed(6)}'),
            if (_locationAccuracy != null)
              Text('Accuracy: ${_locationAccuracy!.toStringAsFixed(1)}m',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      double zoom = _locationAccuracy != null
          ? _locationAccuracy! < 5
              ? 18.0
              : _locationAccuracy! < 20
                  ? 16.0
                  : 15.0
          : 15.0;
      _mapController.move(_userLocation!, zoom);
    }
  }

  void _centerOnRoute() {
    if (currentRouteData.stops.isNotEmpty) {
      _mapController.move(currentRouteData.stops.first, 12.0);
    }
  }

  void _switchRoute(RouteType newRoute) {
    setState(() {
      _currentRoute = newRoute;
      routePoints.clear();
    });
    _fetchRouteFromORS();
    _centerOnRoute();
  }

  void _changeAccuracyLevel(LocationAccuracyLevel newLevel) {
    setState(() {
      _accuracyLevel = newLevel;
    });
    _startLocationTracking(); // Restart with new settings
  }

  void _showAccuracySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black;

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    Text(
                      'Location Accuracy',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                    ),
                    const SizedBox(height: 16),
                    ...LocationAccuracyLevel.values.map((level) {
                      final isSelected = _accuracyLevel == level;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            _changeAccuracyLevel(level);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.purple.withOpacity(0.1)
                                  : textColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.purple
                                    : textColor.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  level == LocationAccuracyLevel.best
                                      ? Icons.gps_fixed
                                      : level == LocationAccuracyLevel.high
                                          ? Icons.my_location
                                          : level ==
                                                  LocationAccuracyLevel.medium
                                              ? Icons.location_searching
                                              : Icons.location_on,
                                  color: isSelected
                                      ? Colors.purple
                                      : textColor.withOpacity(0.7),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getAccuracyLevelName(level),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.purple
                                          : textColor,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: Colors.purple),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRouteSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black;

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    Text(
                      'Select Route',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                    ),
                    const SizedBox(height: 16),
                    ...RouteType.values.map((route) {
                      final routeData = routes[route]!;
                      final isSelected = _currentRoute == route;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            _switchRoute(route);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? routeData.color.withOpacity(0.1)
                                  : textColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? routeData.color
                                    : textColor.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: routeData.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(routeData.icon,
                                      color: routeData.color, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        routeData.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? routeData.color
                                              : textColor,
                                        ),
                                      ),
                                      Text(
                                        '${routeData.stops.length} stops',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: textColor.withOpacity(0.6)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle,
                                      color: routeData.color, size: 24),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMapStyleSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black;

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    Text(
                      'Select Map Style',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: MapStyle.values.length,
                      itemBuilder: (context, index) {
                        final style = MapStyle.values[index];
                        final isSelected = _currentMapStyle == style;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentMapStyle = style;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.purple.withOpacity(0.1)
                                  : textColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.purple
                                    : textColor.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                Icon(
                                  _getStyleIcon(style),
                                  color: isSelected
                                      ? Colors.purple
                                      : textColor.withOpacity(0.7),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getStyleName(style),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.purple
                                          : textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_currentMapStyle == MapStyle.satellite)
                      Container(
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: textColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Show Labels',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            'Display place names and roads',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                          value: _showLabels,
                          onChanged: (value) {
                            setState(() {
                              _showLabels = value;
                            });
                          },
                          activeColor: Colors.purple,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildMapWidget(),

          // Top gradient overlay
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

          // Enhanced app bar with location status
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Location status indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasLocationPermission && _isLocationServiceEnabled
                              ? (_locationAccuracy != null &&
                                      _locationAccuracy! < 10
                                  ? Icons.gps_fixed
                                  : Icons.gps_not_fixed)
                              : Icons.gps_off,
                          color: _hasLocationPermission &&
                                  _isLocationServiceEnabled
                              ? (_locationAccuracy != null &&
                                      _locationAccuracy! < 10
                                  ? Colors.green
                                  : Colors.orange)
                              : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _locationAccuracy != null
                              ? '±${_locationAccuracy!.toStringAsFixed(0)}m'
                              : 'No GPS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Title with route indicator
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: currentRouteData.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentRouteData.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Enhanced map controls
          Positioned(
            top: 120,
            right: 16,
            child: Column(
              children: [
                // Location accuracy selector
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
                    onPressed: _showAccuracySelector,
                    icon: Icon(
                      _accuracyLevel == LocationAccuracyLevel.best
                          ? Icons.gps_fixed
                          : _accuracyLevel == LocationAccuracyLevel.high
                              ? Icons.my_location
                              : _accuracyLevel == LocationAccuracyLevel.medium
                                  ? Icons.location_searching
                                  : Icons.location_on,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Route selector button
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
                    onPressed: _showRouteSelector,
                    icon: Icon(
                      Icons.alt_route,
                      color: currentRouteData.color,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Map style button
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
                    onPressed: _showMapStyleSelector,
                    icon: Icon(
                      Icons.layers,
                      color: textColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // My location button
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
                    onPressed: _centerOnUserLocation,
                    icon: Icon(
                      Icons.my_location,
                      color: _userLocation != null
                          ? Colors.blue
                          : textColor.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Route view button
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
                    onPressed: _centerOnRoute,
                    icon: Icon(
                      Icons.route,
                      color: textColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Enhanced bottom info panel
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
                        // Enhanced route info header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: currentRouteData.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                currentRouteData.icon,
                                color: currentRouteData.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentRouteData.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    '${currentRouteData.stops.length} stops • ${_getStyleName(_currentMapStyle)} view',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _showRouteSelector,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      currentRouteData.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.swap_horiz,
                                  color: currentRouteData.color,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Enhanced stats row with location info
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                Icons.location_pin,
                                'Start',
                                'Stop 0',
                                Colors.green,
                                textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                Icons.flag,
                                'End',
                                'Stop ${currentRouteData.stops.length - 1}',
                                Colors.red,
                                textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                Icons.gps_fixed,
                                'Accuracy',
                                _locationAccuracy != null
                                    ? '±${_locationAccuracy!.toStringAsFixed(0)}m'
                                    : 'No GPS',
                                _locationAccuracy != null &&
                                        _locationAccuracy! < 10
                                    ? Colors.green
                                    : _locationAccuracy != null
                                        ? Colors.orange
                                        : Colors.red,
                                textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                Icons.speed,
                                'Speed',
                                _locationSpeed != null && _locationSpeed! > 0
                                    ? '${(_locationSpeed! * 3.6).toStringAsFixed(0)} km/h'
                                    : '0 km/h',
                                currentRouteData.color,
                                textColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Location update info
                        if (_lastLocationUpdate != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.update,
                                  size: 16,
                                  color: textColor.withOpacity(0.6),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Last updated: ${_getTimeAgo(_lastLocationUpdate!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withOpacity(0.6),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _getAccuracyLevelName(_accuracyLevel)
                                      .split(' ')[0],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Enhanced action buttons
                        Row(children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              Icons.gps_fixed,
                              'Accuracy Mode',
                              Colors.blue,
                              _showAccuracySelector,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  Widget _buildMapWidget() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: currentRouteData.stops.first,
        initialZoom: 12.0,
        onTap: _onTapMap,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Base map layer
        TileLayer(
          urlTemplate: _getMapUrl(),
          subdomains: _getSubdomains(),
          userAgentPackageName: 'com.example.enhanced_map_app',
        ),

        // Labels layer for satellite view
        if (_currentMapStyle == MapStyle.satellite && _showLabels)
          TileLayer(
            urlTemplate:
                "https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c', 'd'],
          ),

        // Route polyline
        if (routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.0,
                color: currentRouteData.color,
                borderStrokeWidth: 2.0,
                borderColor: Colors.white,
              ),
            ],
          ),

        // Enhanced markers
        MarkerLayer(
          markers: [
            // Route stops
            ...currentRouteData.stops.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;
              final isStart = index == 0;
              final isEnd = index == currentRouteData.stops.length - 1;

              return Marker(
                point: stop,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showStopInfo(index, stop),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isStart
                          ? Colors.green
                          : isEnd
                              ? Colors.red
                              : currentRouteData.markerColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isStart
                            ? Icons.play_arrow
                            : isEnd
                                ? Icons.stop
                                : Icons.directions_bus,
                        color: Colors.white,
                        size: isStart || isEnd ? 20 : 16,
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Enhanced user location marker with accuracy circle
            if (_userLocation != null) ...[
              // Accuracy circle
              if (_locationAccuracy != null)
                Marker(
                  point: _userLocation!,
                  width: _locationAccuracy! * 2,
                  height: _locationAccuracy! * 2,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),

              // User location marker
              Marker(
                point: _userLocation!,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      // Accuracy indicator
                      if (_locationAccuracy != null)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _locationAccuracy! < 5
                                  ? Colors.green
                                  : _locationAccuracy! < 20
                                      ? Colors.orange
                                      : Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      IconData icon, String label, String value, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopInfo(int index, LatLng stop) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isStart = index == 0;
        final isEnd = index == currentRouteData.stops.length - 1;
        String stopType = isStart
            ? 'Start'
            : isEnd
                ? 'End'
                : 'Stop';

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isStart
                                ? Colors.green.withOpacity(0.1)
                                : isEnd
                                    ? Colors.red.withOpacity(0.1)
                                    : currentRouteData.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isStart
                                ? Icons.play_arrow
                                : isEnd
                                    ? Icons.stop
                                    : Icons.directions_bus,
                            color: isStart
                                ? Colors.green
                                : isEnd
                                    ? Colors.red
                                    : currentRouteData.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$stopType $index',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                currentRouteData.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coordinates',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Latitude: ${stop.latitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.8),
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            'Longitude: ${stop.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.8),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            Icons.center_focus_strong,
                            'Center on Map',
                            currentRouteData.color,
                            () {
                              _mapController.move(stop, 16.0);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            Icons.copy,
                            'Copy Coords',
                            Colors.grey,
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Coordinates copied: ${stop.latitude.toStringAsFixed(6)}, ${stop.longitude.toStringAsFixed(6)}',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
