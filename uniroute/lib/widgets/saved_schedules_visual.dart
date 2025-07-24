import 'package:flutter/material.dart';

/// A widget that visually represents saved schedules as clickable icons.
/// The widget highlights an icon when hovered over with the mouse.
class SavedSchedulesVisual extends StatelessWidget {
  /// A list of saved schedules, where each schedule is represented as a map.
  final List<Map<String, String>> savedSchedules;

  /// The index of the schedule currently being tapped.
  /// If no schedule is tapped, it is null.
  final int? tappedIndex;

  /// A callback function that notifies when a schedule is tapped.
  /// It receives the index of the tapped schedule.
  final Function(int) onTap;

  /// Constructor for the SavedSchedulesVisual widget.
  const SavedSchedulesVisual({
    super.key,
    required this.savedSchedules,
    required this.tappedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      // Spacing between each icon in the wrap layout.
      spacing: 12,
      // Generate a list of widgets based on the number of saved schedules.
      children: savedSchedules.asMap().entries.map((entry) {
        final idx = entry.key;
        final schedule = entry.value;
        final isTapped = tappedIndex == idx;
        return GestureDetector(
          // When the icon is tapped, call onTap with the current index.
          onTap: () => onTap(idx),
          child: Container(
            decoration: BoxDecoration(
              // Change the background color if the icon is tapped.
              color: isTapped ? Colors.black : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                const Icon(Icons.calendar_month, size: 28),
                Text(
                  schedule['route'] ?? '',
                  style: TextStyle(
                    // Change the text color if the icon is tapped.
                    color: isTapped ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  schedule['time'] ?? '',
                  style: TextStyle(
                    // Change the text color if the icon is tapped.
                    color: isTapped ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
