import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class RouteSelectionPage extends StatefulWidget {
  final void Function(String routeId, String timeRaw) onContinue;
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
  String selectedRouteId = '';
  String selectedRouteName = '';
  String selectedTimeDisplay = '';
  String selectedTimeRaw = '';

  List<Map<String, dynamic>> routes = [];
  Map<String, List<String>> routeTimesRaw = {};
  Map<String, List<String>> routeTimesDisplay = {};

  List<String> displayedTimes = [];
  bool loading = true;

  final String baseUrl = 'http://172.55.4.160:3000/api';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _formatDeparture(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';

    try {
      // If it's time-only like HH:mm or HH:mm:ss
      final timeOnlyReg = RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$');
      if (timeOnlyReg.hasMatch(s)) {
        final parts = s.split(':');
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final dt = DateTime.now().toLocal().copyWith(hour: h, minute: m);
        return DateFormat('hh:mm a').format(dt);
      }

      // Handle full timestamp formats
      String candidate = s;
      if (s.contains(' ') && !s.contains('T')) {
        candidate = s.replaceFirst(' ', 'T');
      }

      final dt = DateTime.parse(candidate).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return s;
    }
  }

  Future<void> _fetchData() async {
    setState(() => loading = true);
    try {
      // Fetch routes
      final routesResp = await http.get(Uri.parse('$baseUrl/routes'));
      if (routesResp.statusCode != 200) {
        throw Exception('Failed to load routes');
      }

      final List routesData = jsonDecode(routesResp.body) as List;
      routes = routesData
          .map((r) {
            return {
              'id': (r['route_id'] ?? '').toString().trim(),
              'name': (r['route_name'] ?? '').toString().trim(),
            };
          })
          .where((r) => r['id']!.isNotEmpty)
          .toList();

      // Fetch route times
      final timesResp = await http.get(Uri.parse('$baseUrl/route_times'));
      if (timesResp.statusCode != 200) {
        throw Exception('Failed to load route times');
      }

      final List timesData = jsonDecode(timesResp.body) as List;

      // Build both raw and display maps keyed by route id
      routeTimesRaw = {};
      routeTimesDisplay = {};

      for (final t in timesData) {
        final rid = (t['route_id'] ?? '').toString().trim();
        final rawTime = (t['departure_time'] ?? '').toString().trim();

        if (rid.isEmpty || rawTime.isEmpty) continue;

        final display = _formatDeparture(rawTime);

        if (!routeTimesRaw.containsKey(rid)) {
          routeTimesRaw[rid] = [];
          routeTimesDisplay[rid] = [];
        }

        routeTimesRaw[rid]!.add(rawTime);
        routeTimesDisplay[rid]!.add(display);
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => loading = false);

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onRouteSelected(String routeId, String routeName) {
    final normalizedId = routeId.toString().trim();
    setState(() {
      selectedRouteId = normalizedId;
      selectedRouteName = routeName;
      selectedTimeDisplay = '';
      selectedTimeRaw = '';

      // Get times for the selected route using route_id
      displayedTimes = List<String>.from(routeTimesDisplay[normalizedId] ?? []);

      // Sort times chronologically
      displayedTimes.sort((a, b) {
        try {
          final format = DateFormat('hh:mm a');
          return format.parse(a).compareTo(format.parse(b));
        } catch (e) {
          return a.compareTo(b);
        }
      });
    });
  }

  void _onTimeSelected(String display) {
    final idx = routeTimesDisplay[selectedRouteId]?.indexOf(display) ?? -1;
    final raw = (idx >= 0 && routeTimesRaw[selectedRouteId] != null)
        ? routeTimesRaw[selectedRouteId]![idx]
        : display;

    setState(() {
      selectedTimeDisplay = display;
      selectedTimeRaw = raw;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Transports', style: GoogleFonts.poppins()),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: widget.onProfileTap,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    child: Column(
                      children: [
                        _buildSectionTitle('ROUTE'),
                        _buildRouteChips(),
                        const SizedBox(height: 32),
                        const Divider(
                            thickness: 1, height: 40, color: Colors.grey),
                        _buildSectionTitle('TIME'),
                        displayedTimes.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  selectedRouteId.isEmpty
                                      ? 'Select a route to see times'
                                      : 'No times available for "$selectedRouteName"',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              )
                            : _buildChoiceChips(displayedTimes,
                                selectedTimeDisplay, _onTimeSelected),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: ElevatedButton(
                            onPressed: selectedRouteId.isNotEmpty &&
                                    selectedTimeDisplay.isNotEmpty
                                ? () {
                                    widget.onContinue(
                                        selectedRouteId, selectedTimeRaw);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey,
                              disabledForegroundColor: Colors.white70,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                              ),
                            ),
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

  Widget _buildRouteChips() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: routes.map((route) {
        final id = route['id']!;
        final name = route['name']!;
        final isSelected = id == selectedRouteId;
        return ChoiceChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              _onRouteSelected(id, name);
            }
          },
          backgroundColor: Colors.black,
          selectedColor: Colors.grey[800],
          labelStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildChoiceChips(
      List<String> options, String selected, ValueChanged<String> onSelected) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final isSelected = option == selected;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onSelected(option);
            }
          },
          backgroundColor: Colors.black,
          selectedColor: Colors.grey[800],
          labelStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );
      }).toList(),
    );
  }

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
          child: Text(title,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ),
    );
  }
}
