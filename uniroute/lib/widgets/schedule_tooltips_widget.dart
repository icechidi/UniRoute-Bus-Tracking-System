import 'package:flutter/material.dart';

/// A widget that displays a tooltip-like popup showing schedule details.
/// Optionally includes a delete button and a background overlay.
class ScheduleTooltipWidget extends StatelessWidget {
  /// The schedule information, expected to contain keys like 'route' and 'time'.
  final Map<String, String> schedule;

  /// The screen position (Offset) where the tooltip should appear.
  final Offset position;

  /// Callback function to handle deletion (optional).
  final VoidCallback? onDelete;

  /// Whether to use dark mode styling.
  final bool darkMode;

  /// Whether to show a semi-transparent overlay behind the tooltip.
  final bool showBackgroundOverlay;

  /// Constructor for the widget.
  const ScheduleTooltipWidget({
    super.key,
    required this.schedule,
    required this.position,
    this.onDelete,
    this.darkMode = false,
    this.showBackgroundOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    // Tooltip widget that shows the schedule information
    final tooltip = Positioned(
      // Adjust position depending on dark mode
      left: darkMode ? position.dx - 100 : position.dx,
      top: darkMode ? position.dy - 120 : position.dy,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: darkMode ? 200 : null, // Fixed width in dark mode
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: darkMode ? Colors.black87 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: darkMode
                ? null // No shadow in dark mode
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the route information
              Text(
                'Route: ${schedule['route'] ?? ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: darkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              // Display the time information
              Text(
                'Time: ${schedule['time'] ?? ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: darkMode ? Colors.white : Colors.black,
                ),
              ),
              // Optional delete button, shown if onDelete callback is provided
              if (onDelete != null)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: onDelete,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // If background overlay is enabled, wrap tooltip in a darkened stack
    if (showBackgroundOverlay) {
      return Stack(
        children: [
          // Full screen dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          // Tooltip on top
          tooltip,
        ],
      );
    }

    // Return just the tooltip without overlay
    return tooltip;
  }
}

