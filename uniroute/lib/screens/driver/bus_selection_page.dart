import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BusSelectionPage extends StatefulWidget {
  final Function(String busId) onBusSelected;
  final VoidCallback onBack;

  const BusSelectionPage({
    super.key,
    required this.onBusSelected,
    required this.onBack,
  });

  @override
  State<BusSelectionPage> createState() => _BusSelectionPageState();
}

class _BusSelectionPageState extends State<BusSelectionPage> {
  List<Map<String, dynamic>> buses = [];
  bool isLoading = true;
  String? error;
  String? rawResponseBody; // for quick debugging if needed

  @override
  void initState() {
    super.initState();
    fetchBuses();
  }

  Future<void> fetchBuses() async {
    setState(() {
      isLoading = true;
      error = null;
      rawResponseBody = null;
    });

    try {
      final response =
          await http.get(Uri.parse('http://185.51.26.203:3000/api/buses'));
      rawResponseBody = response.body;
      print('🟦 raw buses response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        buses = data
            .map((e) =>
                e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e))
            .toList();
        print('🚌 fetched ${buses.length} buses');
      } else {
        error = 'Failed to load buses (status ${response.statusCode})';
        print('❌ fetchBuses error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      error = 'Error fetching buses: $e';
      print('❌ fetchBuses exception: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  void _handleBusTap(Map<String, dynamic> bus) {
    // Accept several possible keys used by different APIs
    final dynamic rawId = bus['bus_id'] ??
        bus['id'] ??
        bus['busId'] ??
        bus['uuid'] ??
        bus['bus_id_str'];

    if (rawId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selected bus has no ID — cannot select.')),
      );
      print('⚠️ Selected bus missing id: $bus');
      return;
    }

    final String busId = rawId.toString();
    print('✅ Bus tapped, id=$busId, bus object=$bus');

    // Call parent callback with the correct bus id
    widget.onBusSelected(busId);

    // Note: parent (DriverHomeScreen) will pop this page after setting state.
    // If you want to pop here instead, uncomment the next line:
    // Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Bus'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchBuses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: fetchBuses,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                        const SizedBox(height: 12),
                        if (rawResponseBody != null)
                          Text(
                              'Raw: ${rawResponseBody!.substring(0, rawResponseBody!.length.clamp(0, 200))}...'),
                      ],
                    ),
                  ),
                )
              : buses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No buses available.'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: fetchBuses,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reload'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchBuses,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: buses.length,
                        itemBuilder: (context, index) {
                          final bus = buses[index];
                          final idCandidate = bus['bus_id'] ??
                              bus['id'] ??
                              bus['busId'] ??
                              bus['uuid'];
                          final number = bus['bus_number']?.toString() ??
                              bus['number']?.toString();
                          final name = bus['name']?.toString();
                          final license =
                              bus['license_plate']?.toString() ?? 'N/A';

                          final title =
                              (number != null && number.trim().isNotEmpty)
                                  ? 'Bus $number'
                                  : (name != null && name.trim().isNotEmpty)
                                      ? name
                                      : (idCandidate != null
                                          ? 'Bus $idCandidate'
                                          : 'Unnamed Bus');

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.directions_bus,
                                  color: Colors.deepPurple),
                              title: Text(title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID: ${idCandidate ?? 'N/A'}'),
                                  Text('License Plate: $license'),
                                ],
                              ),
                              trailing: (idCandidate != null)
                                  ? TextButton(
                                      onPressed: () => _handleBusTap(bus),
                                      child: const Text('Select'),
                                    )
                                  : const Text('No ID',
                                      style: TextStyle(color: Colors.red)),
                              onTap: () => _handleBusTap(bus),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
