// route_selection_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/emergency_button.dart';
import '../widgets/universal_app_bar.dart';
import '../utils/route_services.dart';

class RouteSelectionPage extends StatefulWidget {
  final void Function(String route, String time) onContinue;
  final VoidCallback onProfileTap;

  const RouteSelectionPage({
    super.key,
    required this.onContinue,
    required this.onProfileTap,
  });

  @override
  State<RouteSelectionPage> createState() => _RouteSelectionPageState();
}

class _RouteSelectionPageState extends State<RouteSelectionPage> {
  String selectedRoute = '';
  String? selectedRouteId;
  String selectedTime = '';

  List<Map<String, dynamic>> routes = [];
  List<String> times = [];

  final Map<String, List<String>> _localTimesCache = {};

  bool isLoadingRoutes = true;
  bool isLoadingTimes = false;
  String? errorMsg;

  static const _routesCacheKey = 'cached_routes_v1';
  static const _routeTimesCachePrefix = 'cached_route_times_v1_';

  @override
  void initState() {
    super.initState();
    _loadCachedThenRemoteRoutes();
  }

  /// Helper: normalize routeId safely
  String _extractRouteId(Map<String, dynamic> r) {
    return (r['route_id'] ?? r['id'] ?? r['routeId'] ?? r['raw']?['route_id'])
            ?.toString() ??
        '';
  }

  Future<void> _loadCachedThenRemoteRoutes() async {
    setState(() {
      isLoadingRoutes = true;
      errorMsg = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cached first
      final cached = prefs.getString(_routesCacheKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          final List decoded = json.decode(cached);
          routes = decoded
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
          debugPrint('Loaded ${routes.length} routes from cache');
        } catch (e) {
          debugPrint('Failed to decode cached routes: $e');
        }
      }

      setState(() => isLoadingRoutes = false);

      // Fetch network routes
      final fetched = await RouteServices.fetchRoutes();
      debugPrint('Fetched ${fetched.length} routes from network');

      await prefs.setString(_routesCacheKey, json.encode(fetched));

      setState(() {
        routes = fetched;
        errorMsg = null;
        isLoadingRoutes = false;
      });
    } catch (e) {
      debugPrint('Error loading routes: $e');
      setState(() {
        errorMsg = 'Failed to load routes';
        isLoadingRoutes = false;
      });
    }
  }

  Future<void> _loadTimesForRoute(String routeId) async {
    if (routeId.isEmpty) return;

    setState(() {
      isLoadingTimes = true;
      times = [];
      selectedTime = '';
      errorMsg = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_routeTimesCachePrefix$routeId';

    // Try cached first
    final cachedJson = prefs.getString(cacheKey);
    if (cachedJson != null) {
      try {
        final List decoded = json.decode(cachedJson);
        final cachedList = decoded.map((e) => e.toString()).toList();
        _localTimesCache[routeId] = cachedList;
        setState(() {
          times = cachedList;
          isLoadingTimes = false;
        });
        debugPrint('Loaded ${cachedList.length} times from cache for $routeId');
      } catch (e) {
        debugPrint('Failed to parse cached times: $e');
      }
    }

    // Then fetch fresh
    try {
      final fetched = await RouteServices.fetchRouteTimes(routeId);
      debugPrint('Fetched ${fetched.length} times from network for $routeId');

      _localTimesCache[routeId] = fetched;
      await prefs.setString(cacheKey, json.encode(fetched));

      setState(() {
        times = fetched;
        isLoadingTimes = false;
      });
    } catch (e) {
      debugPrint('Error fetching times for $routeId: $e');
      if (times.isEmpty) {
        setState(() {
          errorMsg = 'Failed to load times';
          isLoadingTimes = false;
        });
      } else {
        setState(() => isLoadingTimes = false);
      }
    }
  }

  void _onRouteTap(String routeName) {
    final chosen = routes.firstWhere(
      (r) => r['route_name'] == routeName,
      orElse: () => <String, dynamic>{},
    );

    final idStr = _extractRouteId(chosen);

    if (idStr.isEmpty) {
      debugPrint('Route id missing for: $chosen');
      setState(() => errorMsg = 'Invalid route id');
      return;
    }

    // Deselect if tapped again
    if (selectedRoute == routeName) {
      setState(() {
        selectedRoute = '';
        selectedRouteId = null;
        times = [];
        selectedTime = '';
      });
      return;
    }

    setState(() {
      selectedRoute = routeName;
      selectedRouteId = idStr;
      selectedTime = '';
      errorMsg = null;
    });

    _loadTimesForRoute(idStr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: UniversalAppBar(
        title: 'Transports',
        onProfileTap: widget.onProfileTap,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoadingRoutes
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    child: Column(
                      children: [
                        _buildSectionTitle('ROUTE'),
                        if (errorMsg != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(errorMsg!,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        _buildChoiceChips(
                          routes
                              .map((r) => r['route_name']?.toString() ?? '')
                              .where((s) => s.isNotEmpty)
                              .toList(),
                          selectedRoute,
                          _onRouteTap,
                        ),
                        const SizedBox(height: 32),
                        const Divider(
                            thickness: 1, height: 40, color: Colors.grey),
                        _buildSectionTitle('TIME'),
                        if (isLoadingTimes)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (selectedRoute.isEmpty)
                          _placeholderText(
                              'Tap a route to show departure times')
                        else if (times.isEmpty)
                          _placeholderText(
                              'No times available for "$selectedRoute"')
                        else
                          _buildChoiceChips(times, selectedTime, (val) {
                            setState(() => selectedTime = val);
                          }),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: ElevatedButton(
                            onPressed: selectedRoute.isNotEmpty &&
                                    selectedTime.isNotEmpty
                                ? () => widget.onContinue(
                                    selectedRoute, selectedTime)
                                : null,
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.disabled)
                                        ? Colors.black.withOpacity(0.4)
                                        : Colors.black,
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all(Colors.white),
                              minimumSize: WidgetStateProperty.all(
                                  const Size.fromHeight(50)),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              overlayColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const EmergencyButton(bottomSpacing: 0),
        ],
      ),
    );
  }

  Widget _placeholderText(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(msg, style: GoogleFonts.poppins(fontSize: 14)),
      );

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 100, 174),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChips(
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final bool isSelected = option == selected;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            constraints: const BoxConstraints(minWidth: 90, maxWidth: 140),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[900] : Colors.black,
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              option,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
