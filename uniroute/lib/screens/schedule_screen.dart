import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> schedules = [
      {"route": "Bus 101", "time": "08:00 AM", "destination": "Main Campus"},
      {"route": "Bus 102", "time": "09:30 AM", "destination": "North Station"},
      {"route": "Bus 103", "time": "11:00 AM", "destination": "City Center"},
      {"route": "Bus 104", "time": "01:15 PM", "destination": "Main Campus"},
      {"route": "Bus 105", "time": "03:45 PM", "destination": "North Station"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        centerTitle: true,
        backgroundColor: Colors.black87,
      ),
      body: ListView.builder(
        itemCount: schedules.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.directions_bus, color: Colors.black87),
              title: Text(schedule["route"] ?? ""),
              subtitle: Text("Destination: ${schedule["destination"]}"),
              trailing: Text(
                schedule["time"] ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
