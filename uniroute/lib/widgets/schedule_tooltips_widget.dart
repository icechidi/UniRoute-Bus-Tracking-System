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
    final screenWidth = MediaQuery.of(context).size.width;
    double left = position.dx - 20;
    const double boxWidth = 200;
    // If the box would overflow to the right, shift it left
    if (left + boxWidth > screenWidth) {
      left = screenWidth - boxWidth - 16; // 16px margin from right edge
      if (left < 0) left = 8; // Ensure not off the left edge
    }
    final tooltip = Positioned(
      left: left,
      top: position.dy - 70,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route: ${schedule['route'] ?? ''}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Time: ${schedule['time'] ?? ''}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
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
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
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

