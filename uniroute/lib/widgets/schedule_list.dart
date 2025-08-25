import 'package:flutter/material.dart';

class ScheduleList extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;
  final Function(int) onDelete;

  const ScheduleList({super.key, required this.schedules, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(schedules.length, (index) {
        final item = schedules[index];
        return Card(
          color: Colors.blue[50],
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.directions_bus, color: Colors.blue),
            title: Text('${item['route']}'),
            subtitle: Text('Time: ${item['time']}\nReminder: ${item['hour']}h ${item['minute']}m before'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(index),
            ),
          ),
        );
      }),
    );
  }
}
