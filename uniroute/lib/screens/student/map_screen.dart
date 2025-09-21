// lib/screens/student/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../student/map_logic.dart';

enum MapStyle { googleLike, standard, satellite }

class MapScreen extends StatefulWidget {
  /// Accept multiple bus IDs (e.g. ['1','2','3']). Defaults to ['1'].
  final List<String> busIds;
  const MapScreen(
      {super.key, this.busIds = const ['1', '2', '3', '4', '5', '6']});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // One MapLogic instance per bus id
  final Map<String, MapLogic> _logics = {};
  // Keep the listener references so we can remove them on dispose
  final Map<String, VoidCallback> _logicListeners = {};

  bool _isLoadingRoutes = true;
  MapStyle _currentMapStyle = MapStyle.googleLike;

  LatLng? _currentCenter;
  double _currentZoom = 13.0;

  // Which bus the UI is focused on (routes/stops), defaults to first bus
  late String _focusedBusId;

  // Color per bus id (1..6). Adjust as needed.
  final Map<String, Color> _busColors = {
    '1': Colors.green,
    '2': Colors.blue,
    '3': Colors.red,
    '4': Colors.orange,
    '5': Colors.purple,
    '6': Colors.teal,
  };

  @override
  void initState() {
    super.initState();
    _focusedBusId = widget.busIds.isNotEmpty ? widget.busIds.first : '1';
    _initLogics();
  }

  Future<void> _initLogics() async {
    setState(() => _isLoadingRoutes = true);

    // Create the MapLogic instances
    for (final id in widget.busIds) {
      final logic = MapLogic(busId: id);
      _logics[id] = logic;
      // Create a listener that calls setState when any logic changes
      listener() => setState(() {});
      logic.addListener(listener);
      _logicListeners[id] = listener;
    }

    // Init all logics concurrently
    await Future.wait(_logics.values.map((l) => l.init()));

    // Determine initial center (prefer focused bus initialCenter if available)
    final focused = _logics[_focusedBusId];
    _currentCenter = focused?.initialCenter ??
        (_logics.values.isNotEmpty ? _logics.values.first.initialCenter : null);
    _currentZoom = 13.0;
    if (_currentCenter != null) _centerOn(_currentCenter);

    setState(() => _isLoadingRoutes = false);
  }

  @override
  void dispose() {
    // Remove each listener and dispose each logic
    for (final id in _logics.keys) {
      final logic = _logics[id];
      final listener = _logicListeners[id];
      if (logic != null && listener != null) {
        logic.removeListener(listener);
      }
      logic?.disposeLogic();
    }
    _logics.clear();
    _logicListeners.clear();
    super.dispose();
  }

  void _centerOn(LatLng? target) {
    if (target == null) return;
    _currentCenter = target;
    try {
      _mapController.move(target, _currentZoom);
    } catch (_) {}
  }

  Future<void> _onRouteSelected(String busId, int? routeId) async {
    if (routeId == null) return;
    final logic = _logics[busId];
    if (logic == null) return;
    logic.currentRouteId = routeId;
    await logic.fetchRouteFromORS();
    _centerOn(logic.initialCenter);
  }

  String _getMapUrl() {
    switch (_currentMapStyle) {
      case MapStyle.googleLike:
        return "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png";
      case MapStyle.standard:
        return "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
      case MapStyle.satellite:
        return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}";
    }
  }

  List<String> _getSubdomains() {
    switch (_currentMapStyle) {
      case MapStyle.googleLike:
        return ['a', 'b', 'c', 'd'];
      case MapStyle.standard:
        return ['a', 'b', 'c'];
      case MapStyle.satellite:
        return [''];
    }
  }

  String _getAttribution() {
    switch (_currentMapStyle) {
      case MapStyle.googleLike:
        return '© OpenStreetMap contributors • © CARTO';
      case MapStyle.standard:
        return '© OpenStreetMap contributors';
      case MapStyle.satellite:
        return 'Sources: Esri, DigitalGlobe, Earthstar Geographics';
    }
  }

  void _setMapStyle(MapStyle style) {
    setState(() {
      _currentMapStyle = style;
    });
    final c = _currentCenter;
    if (c != null) _mapController.move(c, _currentZoom);
  }

  @override
  Widget build(BuildContext context) {
    final focusedLogic = _logics[_focusedBusId];
    final routeData =
        (focusedLogic != null && focusedLogic.currentRouteId != null)
            ? focusedLogic.routes[focusedLogic.currentRouteId]
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Buses: ${widget.busIds.join(", ")}'),
        actions: [
          // Bus selection dropdown (choose which bus to focus UI on)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _focusedBusId,
                items: widget.busIds
                    .map((id) => DropdownMenuItem(
                          value: id,
                          child: Text('Bus $id'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _focusedBusId = v;
                  });
                  // center on newly focused bus center if available
                  final f = _logics[_focusedBusId];
                  if (f?.initialCenter != null) _centerOn(f!.initialCenter);
                },
                hint: const Text('Focus bus'),
              ),
            ),
          ),

          // route dropdown for focused bus
          if (focusedLogic != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildRouteDropdownForFocused(focusedLogic),
            ),

          PopupMenuButton<MapStyle>(
            onSelected: (style) => _setMapStyle(style),
            icon: const Icon(Icons.map),
            itemBuilder: (ctx) => [
              _mapStyleItem(MapStyle.googleLike, 'Google-like (light)'),
              _mapStyleItem(MapStyle.standard, 'OpenStreetMap'),
              _mapStyleItem(MapStyle.satellite, 'Satellite'),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter ?? const LatLng(35.1264, 33.4299),
              initialZoom: _currentZoom,
              onMapEvent: (event) {
                try {
                  final cam = (event as dynamic).camera;
                  if (cam != null) {
                    _currentCenter = cam.center;
                    _currentZoom = cam.zoom;
                  }
                } catch (_) {}
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _getMapUrl(),
                subdomains: _getSubdomains(),
              ),

              // Route polylines for every bus (if present)
              PolylineLayer(
                polylines: _logics.entries
                    .where((e) => e.value.routePolyline.isNotEmpty)
                    .map((e) => Polyline(
                          points: e.value.routePolyline,
                          strokeWidth: 4.5,
                          color: _busColors[e.key] ?? Colors.blue,
                        ))
                    .toList(),
              ),

              // Markers: stops for focused bus, user for focused bus,
              // and bus markers for ALL buses (1..6)
              MarkerLayer(
                markers: [
                  // stops for focused route
                  if (routeData != null)
                    ...routeData.stops.map((s) => Marker(
                          width: 28,
                          height: 28,
                          point: s,
                          child: const Icon(Icons.location_on, size: 28),
                        )),

                  // user location (from focused logic)
                  if (focusedLogic != null && focusedLogic.userLocation != null)
                    Marker(
                      width: 36,
                      height: 36,
                      point: focusedLogic.userLocation!,
                      child: const Icon(
                        Icons.person_pin_circle,
                        size: 36,
                        color: Colors.green,
                      ),
                    ),

                  // Bus location markers for ALL logics
                  for (final entry in _logics.entries)
                    if (entry.value.busLocation != null &&
                        entry.value.isBusActive)
                      Marker(
                        width: 56,
                        height: 56,
                        point: entry.value.busLocation!,
                        child: Container(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'BUS ${entry.key}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                              const SizedBox(height: 4),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    _busColors[entry.key] ?? Colors.green,
                                child: const Icon(Icons.directions_bus,
                                    size: 18, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),

              // Attribution box
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    _getAttribution(),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoadingRoutes)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'center_user',
            onPressed: () => _centerOn(_logics[_focusedBusId]?.userLocation),
            tooltip: 'Center on you (focused bus)',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'center_bus',
            onPressed: () => _centerOn(_logics[_focusedBusId]?.busLocation ??
                _logics[_focusedBusId]?.initialCenter),
            tooltip: 'Center on focused bus',
            child: const Icon(Icons.directions_bus),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'cycle_bus',
            onPressed: () {
              // cycle focus through available buses
              final idx = widget.busIds.indexOf(_focusedBusId);
              final next = widget.busIds[(idx + 1) % widget.busIds.length];
              setState(() {
                _focusedBusId = next;
              });
              final f = _logics[_focusedBusId];
              if (f?.initialCenter != null) _centerOn(f!.initialCenter);
            },
            tooltip: 'Cycle focused bus',
            child: const Icon(Icons.swap_horiz),
          ),
        ],
      ),
      bottomNavigationBar: _buildInfoBar(),
    );
  }

  PopupMenuItem<MapStyle> _mapStyleItem(MapStyle style, String label) {
    return PopupMenuItem(
      value: style,
      child: Row(
        children: [
          Radio<MapStyle>(
            value: style,
            groupValue: _currentMapStyle,
            onChanged: (v) => _setMapStyle(style),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildRouteDropdownForFocused(MapLogic focusedLogic) {
    if (_isLoadingRoutes) {
      return const Center(
        child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final items = focusedLogic.routes.entries
        .map((e) =>
            DropdownMenuItem<int>(value: e.key, child: Text(e.value.name)))
        .toList();

    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: focusedLogic.currentRouteId,
        items: items,
        onChanged: (v) async {
          await _onRouteSelected(_focusedBusId, v);
        },
        hint: const Text('Select route'),
      ),
    );
  }

  Widget _buildInfoBar() {
    // Show a compact list of status/coords for each bus
    final children = _logics.entries.map((e) {
      final l = e.value;
      final busCoords = l.busLocation != null
          ? '${l.busLocation!.latitude.toStringAsFixed(6)}, ${l.busLocation!.longitude.toStringAsFixed(6)}'
          : 'not available';
      final status = l.busStatus ?? (l.isBusActive ? 'active' : 'inactive');
      return Row(
        children: [
          CircleAvatar(
              radius: 8, backgroundColor: _busColors[e.key] ?? Colors.grey),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bus ${e.key} • $status',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              Text(busCoords, style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(width: 12),
        ],
      );
    }).toList();

    final focusedLogic = _logics[_focusedBusId];
    final focusedRouteData =
        (focusedLogic != null && focusedLogic.currentRouteId != null)
            ? focusedLogic.routes[focusedLogic.currentRouteId]
            : null;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surface,
      height: 80, // keep it a bit taller for multiple entries
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: children,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _centerOn(_logics[_focusedBusId]?.initialCenter),
            child: const Text('Center'),
          ),
        ],
      ),
    );
  }
}
