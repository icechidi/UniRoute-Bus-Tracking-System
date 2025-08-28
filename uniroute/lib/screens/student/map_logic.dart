// lib/screens/student/map_logic.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class RouteData {
  final int routeId;
  final String name;
  final List<LatLng> stops;
  final int colorValue;

  RouteData({
    required this.routeId,
    required this.name,
    required this.stops,
    required this.colorValue,
  });
}

class MapLogic extends ChangeNotifier {
  final String busId; // used for RTDB listening
  int? currentRouteId;

  // Instance view of routes (backed by _globalRoutes)
  final Map<int, RouteData> routes = {};

  // Exposed to UI
  List<LatLng> routePolyline = [];
  LatLng? userLocation;
  double? locationAccuracy;

  // Latest bus GPS reported in RTDB
  LatLng? busLocation;
  String? busStatus;
  bool get isBusActive => busStatus?.toLowerCase().trim() == 'active';

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<DatabaseEvent>? _busLocationSub;

  // --- configure ---
  // Put your API base here; make static so it's consistent across instances
  static const String apiBaseUrl = 'http://172.55.4.160:3000';

  // ORS key (optional — keep empty to disable ORS usage)
  static const String _orsApiKey =
      String.fromEnvironment('ORS_API_KEY', defaultValue: '');

  static const double _densifyStepMeters = 20.0;

  // -----------------
  // Shared caches so multiple MapLogic instances don't repeat work.
  static final Map<int, RouteData> _globalRoutes = {};
  static final Map<int, List<LatLng>> _globalPolylineCache = {};

  // Shared http client
  static final http.Client _httpClient = http.Client();

  // Geolocation notify coalescing
  Timer? _notifyTimer;
  bool _pendingLocationUpdate = false;

  MapLogic({required this.busId});

  /// Initialize: device location, routes & ORS polyline, then RTDB listener
  Future<void> init() async {
    await _initLocation();
    await fetchRoutesFromDb();
    if (currentRouteId != null) await fetchRouteFromORS();
    await _initRtdbListener();
  }

  /// Device location (optional) — throttles frequent notifyListeners calls.
  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      userLocation = LatLng(pos.latitude, pos.longitude);
      locationAccuracy = pos.accuracy;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error getting current position: $e');
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((position) {
      userLocation = LatLng(position.latitude, position.longitude);
      locationAccuracy = position.accuracy;

      // Coalesce multiple frequent updates: notify at most every 400ms
      _pendingLocationUpdate = true;
      _notifyTimer ??= Timer(const Duration(milliseconds: 400), () {
        if (_pendingLocationUpdate) {
          _pendingLocationUpdate = false;
          notifyListeners();
        }
        _notifyTimer?.cancel();
        _notifyTimer = null;
      });
    });
  }

  /// Initialize RTDB listener (safe initialization of Firebase).
  /// Listens to `trips/<busId>` so we can read both `status` and `location`.
  Future<void> _initRtdbListener() async {
    if (busId.isEmpty) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final app = Firebase.app();

      final rtdb = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://uniroute-36e10-default-rtdb.europe-west1.firebasedatabase.app',
      );

      final ref = rtdb.ref('trips/$busId');

      await _busLocationSub?.cancel();
      _busLocationSub = ref.onValue.listen((DatabaseEvent event) {
        final val = event.snapshot.value;

        if (val == null) {
          busLocation = null;
          busStatus = null;
          notifyListeners();
          return;
        }

        if (val is Map) {
          final Map<dynamic, dynamic> node = Map<dynamic, dynamic>.from(val);

          final statusRaw = node['status'] ?? node['state'];
          busStatus = statusRaw != null ? statusRaw.toString() : null;

          final loc = node['location'];
          double? lat;
          double? lng;
          if (loc is Map) {
            lat = _toDouble(loc['lat']) ?? _toDouble(loc['latitude']);
            lng = _toDouble(loc['lng']) ?? _toDouble(loc['longitude']);
          } else {
            lat = _toDouble(node['lat']) ?? _toDouble(node['latitude']);
            lng = _toDouble(node['lng']) ?? _toDouble(node['longitude']);
          }

          if (lat != null && lng != null) {
            busLocation = LatLng(lat, lng);
          } else {
            busLocation = null;
          }

          notifyListeners();
          return;
        }

        // Non-map payload
        busLocation = null;
        busStatus = null;
        notifyListeners();
      }, onError: (err) {
        if (kDebugMode) print('RTDB listener error for trips/$busId: $err');
      });
    } catch (e, st) {
      if (kDebugMode) print('Error setting up RTDB listener: $e\n$st');
    }
  }

  /// Fetch routes from backend. Uses a shared global cache to avoid re-fetch
  Future<void> fetchRoutesFromDb({bool forceRefresh = false}) async {
    // If global cache exists and not forcing refresh, copy to instance map
    if (_globalRoutes.isNotEmpty && !forceRefresh) {
      routes
        ..clear()
        ..addAll(_globalRoutes);
      currentRouteId ??= routes.keys.isNotEmpty ? routes.keys.first : null;
      return;
    }

    final url = Uri.parse('$apiBaseUrl/api/route-stops');
    if (kDebugMode) print('Fetching routes from $url');

    try {
      final resp =
          await _httpClient.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        if (kDebugMode) {
          final preview = resp.body.length > 500
              ? '${resp.body.substring(0, 500)}...'
              : resp.body;
          print(
              'Failed to fetch route_stops: ${resp.statusCode} - preview:\n$preview');
        }
        return;
      }

      final body = jsonDecode(resp.body);
      if (body is! List) {
        if (kDebugMode)
          print('Unexpected route_stops response format; expected array.');
        return;
      }

      final Map<int, List<Map<String, dynamic>>> grouped = {};
      for (var raw in body) {
        if (raw is! Map<String, dynamic>) continue;
        final routeId = _toInt(raw['route_id']);
        final stopOrder = _toInt(raw['stop_order']);
        final lat = _toDouble(raw['latitude']) ?? _toDouble(raw['lat']);
        final lng = _toDouble(raw['longitude']) ?? _toDouble(raw['lng']);

        if (routeId == null || stopOrder == null || lat == null || lng == null)
          continue;

        grouped.putIfAbsent(routeId, () => []).add({
          'stop_order': stopOrder,
          'latitude': lat,
          'longitude': lng,
        });
      }

      // Build route objects
      _globalRoutes.clear();
      const defaultColors = [
        0xFF4CAF50,
        0xFFFF9800,
        0xFF2196F3,
        0xFFE91E63,
        0xFF9C27B0,
        0xFF3F51B5,
      ];

      grouped.forEach((routeId, list) {
        list.sort((a, b) =>
            (a['stop_order'] as int).compareTo(b['stop_order'] as int));
        final stops = list
            .map((s) =>
                LatLng((s['latitude'] as double), (s['longitude'] as double)))
            .toList();
        final name = 'Route $routeId';
        final colorValue = defaultColors[routeId % defaultColors.length];
        _globalRoutes[routeId] = RouteData(
            routeId: routeId, name: name, stops: stops, colorValue: colorValue);
      });

      // copy into instance map
      routes
        ..clear()
        ..addAll(_globalRoutes);

      _globalPolylineCache.clear();
      currentRouteId ??= routes.keys.isNotEmpty ? routes.keys.first : null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error fetching route_stops: $e');
    }
  }

  // ORS / densify logic: uses global polyline cache when available
  Future<void> fetchRouteFromORS() async {
    if (currentRouteId == null || !routes.containsKey(currentRouteId)) return;

    if (_globalPolylineCache.containsKey(currentRouteId)) {
      routePolyline = List<LatLng>.from(_globalPolylineCache[currentRouteId]!);
      notifyListeners();
      return;
    }

    final currentRouteData = routes[currentRouteId]!;
    final stops = currentRouteData.stops;
    if (stops.length < 2) {
      routePolyline = List<LatLng>.from(stops);
      _globalPolylineCache[currentRouteId!] = routePolyline;
      notifyListeners();
      return;
    }

    if (_orsApiKey.isEmpty) {
      if (kDebugMode) print('ORS key not set — densifying stops locally.');
      final dens = _densifyPolyline(stops, _densifyStepMeters);
      _globalPolylineCache[currentRouteId!] = dens;
      routePolyline = dens;
      notifyListeners();
      return;
    }

    const int maxWaypoints = 50;
    const int step = maxWaypoints - 1;
    List<LatLng> fullPolyline = [];

    Future<List<LatLng>?> fetchPolylineForCoords(
        List<LatLng> coordsSegment) async {
      final coords =
          coordsSegment.map((p) => [p.longitude, p.latitude]).toList();
      final url = Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car/geojson');

      try {
        final response = await _httpClient
            .post(url,
                headers: {
                  'Authorization': _orsApiKey,
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(
                    {'coordinates': coords, 'preference': 'recommended'}))
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final coordsList = data['features']?[0]?['geometry']?['coordinates']
              as List<dynamic>?;
          if (coordsList != null) {
            return coordsList
                .map((c) =>
                    LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                .toList();
          }
        } else {
          if (kDebugMode) {
            final preview = response.body.length > 500
                ? '${response.body.substring(0, 500)}...'
                : response.body;
            print('ORS returned ${response.statusCode}. Preview: $preview');
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error calling ORS: $e');
      }
      return null;
    }

    if (stops.length <= maxWaypoints) {
      final seg = await fetchPolylineForCoords(stops);
      if (seg != null && seg.isNotEmpty) {
        fullPolyline = seg;
        _globalPolylineCache[currentRouteId!] = fullPolyline;
        routePolyline = fullPolyline;
        notifyListeners();
        return;
      } else {
        if (kDebugMode) print('ORS single-call failed; densifying locally.');
        final dens = _densifyPolyline(stops, _densifyStepMeters);
        _globalPolylineCache[currentRouteId!] = dens;
        routePolyline = dens;
        notifyListeners();
        return;
      }
    }

    for (int i = 0; i < stops.length; i += step) {
      final end = min(i + maxWaypoints, stops.length);
      final segmentStops = stops.sublist(i, end);
      final segmentPolyline = await fetchPolylineForCoords(segmentStops);

      if (segmentPolyline == null || segmentPolyline.isEmpty) {
        if (kDebugMode)
          print(
              'ORS chunk call failed; falling back to local densify for full route.');
        fullPolyline = _densifyPolyline(stops, _densifyStepMeters);
        break;
      }

      if (fullPolyline.isEmpty) {
        fullPolyline.addAll(segmentPolyline);
      } else {
        final firstOfSegment = segmentPolyline.first;
        if (_latLngEquals(fullPolyline.last, firstOfSegment)) {
          fullPolyline.addAll(segmentPolyline.sublist(1));
        } else {
          fullPolyline.addAll(segmentPolyline);
        }
      }
    }

    _globalPolylineCache[currentRouteId!] = fullPolyline;
    routePolyline = fullPolyline;
    notifyListeners();
  }

  List<LatLng> _densifyPolyline(List<LatLng> stops, double stepMeters) {
    if (stops.length < 2) return List<LatLng>.from(stops);

    final Distance distance = const Distance();
    final List<LatLng> result = [];

    for (int i = 0; i < stops.length - 1; i++) {
      final a = stops[i];
      final b = stops[i + 1];
      result.add(a);

      final meters = distance(a, b);
      if (meters <= 0) continue;

      final segments = meters / stepMeters;
      final int count = segments < 1 ? 0 : segments.ceil();

      for (int s = 1; s < count; s++) {
        final t = s / count;
        result.add(_interpolateLatLng(a, b, t));
      }
    }

    result.add(stops.last);
    return result;
  }

  LatLng _interpolateLatLng(LatLng a, LatLng b, double t) {
    final lat = a.latitude + (b.latitude - a.latitude) * t;
    final lng = a.longitude + (b.longitude - a.longitude) * t;
    return LatLng(lat, lng);
  }

  bool _latLngEquals(LatLng a, LatLng b, [double tol = 1e-6]) {
    return (a.latitude - b.latitude).abs() <= tol &&
        (a.longitude - b.longitude).abs() <= tol;
  }

  Future<void> switchRoute() async {
    if (routes.isEmpty) return;
    final keys = routes.keys.toList();
    final currentIndex = keys.indexOf(currentRouteId ?? keys.first);
    currentRouteId = keys[(currentIndex + 1) % keys.length];
    await fetchRouteFromORS();
    notifyListeners();
  }

  LatLng get initialCenter {
    if (currentRouteId != null && routes.containsKey(currentRouteId)) {
      return userLocation ?? routes[currentRouteId]!.stops.first;
    }
    return userLocation ?? const LatLng(35.211350, 33.237250);
  }

  void disposeLogic() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _busLocationSub?.cancel();
    _busLocationSub = null;
    _notifyTimer?.cancel();
    _notifyTimer = null;
  }

  // Utility: clear global caches (useful in dev or when server data changes)
  static void clearGlobalCache() {
    _globalRoutes.clear();
    _globalPolylineCache.clear();
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
