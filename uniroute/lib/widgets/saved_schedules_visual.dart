import 'package:flutter/material.dart';

/// A widget that visually represents saved schedules as clickable icons.
/// The widget highlights an icon when hovered over with the mouse.
class SavedSchedulesVisual extends StatelessWidget {
  /// A list of saved schedules, where each schedule is represented as a map.
  final List<Map<String, String>> savedSchedules;

  /// The index of the schedule currently being hovered over.
  /// If no schedule is hovered, it is null.
  final int? hoveredIndex;

  /// A callback function that notifies when the hover state changes.
  /// It receives the index of the hovered schedule or null if none.
  final Function(int?) onHoverChange;

  /// Constructor for the SavedSchedulesVisual widget.
  const SavedSchedulesVisual({
    super.key,
    required this.savedSchedules,
    required this.hoveredIndex,
    required this.onHoverChange,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      // Spacing between each icon in the wrap layout.
      spacing: 12,
      // Generate a list of widgets based on the number of saved schedules.
      children: List.generate(savedSchedules.length, (index) {
        return MouseRegion(
          // When the mouse enters this icon region, call onHoverChange with the current index.
          onEnter: (_) => onHoverChange(index),
          // When the mouse exits the icon region, call onHoverChange with null.
          onExit: (_) => onHoverChange(null),
          // The child widget displays a calendar icon.
          child: Icon(
            Icons.calendar_month,
            size: 32,
            // Conditionally change the icon's color based on whether it is hovered.
            color: hoveredIndex == index ? Colors.blue : Colors.black,
          ),
        );
      }),
    );
  }
}
