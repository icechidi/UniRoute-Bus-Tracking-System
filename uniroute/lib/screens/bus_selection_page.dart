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

  @override
  void initState() {
    super.initState();
    fetchBuses();
  }

  Future<void> fetchBuses() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await http.get(Uri.parse('https://172.55.4.160:3000/api/buses'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        buses = data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        error = 'Failed to load buses';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    setState(() {
      isLoading = false;
    });
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView.builder(
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    final bus = buses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.directions_bus, color: Colors.deepPurple),
                        title: Text(bus['name'] ?? 'Bus ${bus['id']}'),
                        subtitle: Text('ID: ${bus['id']}'),
                        onTap: () => widget.onBusSelected(bus['id'].toString()),
                      ),
                    );
                  },
                ),
    );
  }
}