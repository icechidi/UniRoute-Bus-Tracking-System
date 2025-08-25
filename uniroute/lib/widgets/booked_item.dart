import 'package:flutter/material.dart';

class BookedItem {
  final String route;
  final String time;
  final String day;
  final int reminderHour;
  final int reminderMinute;
  bool enabled;

  BookedItem({
    required this.route,
    required this.time,
    required this.day,
    required this.reminderHour,
    required this.reminderMinute,
    this.enabled = true,
  });
}

class BookedItemCard extends StatelessWidget {
  final BookedItem item;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleEnabled;

  const BookedItemCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Opacity(
        opacity: item.enabled ? 1.0 : 0.5,
        child: Card(
          color: const Color.fromARGB(255, 38, 93, 177),
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
                      icon: const Icon(Icons.delete, color: Colors.white, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onDelete,
                    ),
                  ],
                ),
                Text('Route: ${item.route}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Reminder: ${item.reminderHour}h ${item.reminderMinute}m', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('Time: ${item.time}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('Day: ${item.day}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Switch(
                      value: item.enabled,
                      onChanged: onToggleEnabled,
                      activeColor: Colors.white,
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white24,
                    ),
                    const Text('Enable', style: TextStyle(color: Colors.white, fontSize: 12)),
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
