import 'package:flutter/material.dart';

/// A widget that displays a day's schedule row with the day name,
/// a list of route/time entries (as icons), and an add button.
class DayScheduleRow extends StatelessWidget {
  /// The name of the day (e.g., "Monday").
  final String day;

  /// A list of entries, where each entry is a map with route/time information.
  final List<Map<String, String>> entries;

  /// Callback when the add button is pressed.
  final VoidCallback onAdd;

  /// Callback when an entry is tapped, providing the entry and the tap position.
  final void Function(Map<String, String>, TapDownDetails) onTapEntry;

  /// Constructor for the DayScheduleRow widget.
  const DayScheduleRow({
    super.key,
    required this.day,
    required this.entries,
    required this.onAdd,
    required this.onTapEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Adds spacing around the row for better layout.
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          // Displays the name of the day.
          Text(day, style: const TextStyle(fontSize: 16)),

          // Pushes remaining widgets to the end of the row.
          const Spacer(),

          // If there are no entries, show a placeholder text.
          if (entries.isEmpty)
            const Text(
              "Select route, time",
              style: TextStyle(color: Colors.grey),
            ),

          // Displays a list of icons, each representing an entry.
          Wrap(
            spacing: 6, // Spacing between icons.
            children: entries.map((entry) {
              return GestureDetector(
                // Calls the onTapEntry callback with the entry and tap position.
                onTapDown: (details) => onTapEntry(entry, details),
                child: const Icon(Icons.calendar_month),
              );
            }).toList(),
          ),

          // Adds spacing between the entries and the add button.
          const SizedBox(width: 10),

          // Button to add a new entry.
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}