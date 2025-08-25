// weekly_booked_widget.dart
import 'package:flutter/material.dart';

class BookedItem {
  final String route;
  final String time;
  final String day;
  bool enabled;

  BookedItem({
    required this.route,
    required this.time,
    required this.day,
    this.enabled = true,
  });
}

class WeeklyBookedWidget extends StatelessWidget {
  final BookedItem item;
  final int reminderHour;
  final int reminderMinute;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const WeeklyBookedWidget({
    super.key,
    required this.item,
    required this.reminderHour,
    required this.reminderMinute,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Opacity(
        opacity: item.enabled ? 1.0 : 0.5,
        child: Card(
          color: Colors.blue[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onDelete,
                    ),
                  ],
                ),
                Text(
                  'Route: ${item.route}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reminder: ${reminderHour}h ${reminderMinute}m',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Time: ${item.time}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Day: ${item.day}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Enable', style: TextStyle(color: Colors.white, fontSize: 12)),
                    Switch(
                      value: item.enabled,
                      onChanged: onToggle,
                      activeColor: Colors.white,
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
