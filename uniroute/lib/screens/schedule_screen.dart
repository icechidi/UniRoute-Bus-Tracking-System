import 'package:flutter/material.dart';
import '../widgets/selection_chips.dart';
import '../widgets/saved_schedules_visual.dart';
import '../widgets/weekly_booking_section.dart';
import '../widgets/schedule_tooltips_widget.dart';
//import '../routes.dart'; // Reserved for future use or previously unused routes

/// Main Schedule screen widget, which allows users to:
/// - Select a route
/// - Choose a time
/// - Save combinations
/// - View weekly booking
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // List of predefined routes
  final List<String> routes = [
    "Gönyeli",
    "Lefkoşa - Hamitköy",
    "Lefkoşa - Honda",
    "Grine",
    "Güzelyurt",
    "Lefkoşa - Hastane",
  ];

  // List of predefined times
  final List<String> times = [
    "07:45",
    "09:45",
    "11:45",
    "12:45",
    "13:45",
    "15:45",
    "17:30",
    "20:00"
  ];

  int? selectedRouteIndex; // Currently selected route index
  int? selectedTimeIndex;  // Currently selected time index
  List<Map<String, String>> savedSchedules = []; // List of saved route-time pairs
  int? hoveredScheduleIndex; // Index for currently hovered schedule (for tooltip display)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 32),
          onPressed: () => Navigator.pop(context), // Navigate back
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Schedule", style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ListView(
              children: [
                // Route Selection Section
                _buildSectionHeader("Route"),
                const SizedBox(height: 24),
                SelectionChips(
                  items: routes,
                  selectedIndex: selectedRouteIndex,
                  onSelected: (index) {
                    setState(() => selectedRouteIndex = selectedRouteIndex == index ? null : index);
                  },
                ),
                const SizedBox(height: 16),

                // Time Selection Section
                _buildSectionHeader("Time"),
                const SizedBox(height: 24),
                SelectionChips(
                  items: times,
                  selectedIndex: selectedTimeIndex,
                  onSelected: (index) {
                    setState(() => selectedTimeIndex = selectedTimeIndex == index ? null : index);
                  },
                ),
                const SizedBox(height: 20),

                // Saved Daily Schedules
                const Text("Daily", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                SavedSchedulesVisual(
                  savedSchedules: savedSchedules,
                  hoveredIndex: hoveredScheduleIndex,
                  onHoverChange: (index) {
                    setState(() => hoveredScheduleIndex = index);
                  },
                ),
                const SizedBox(height: 24),

                // Save Button
                _buildSaveButton(),
                const SizedBox(height: 24),

                // Weekly Booking Section (visual representation)
                WeeklyBookingSection(),
              ],
            ),

            // Tooltip displayed when hovering over a saved schedule
            if (hoveredScheduleIndex != null)
              ScheduleTooltipWidget(
                schedule: savedSchedules[hoveredScheduleIndex!],
                position: _calculateTooltipPosition(context, hoveredScheduleIndex!),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a styled section header with optional weekly icon
  Widget _buildSectionHeader(String label, {bool isWeekly = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(171, 61, 61, 61),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWeekly)
              const Icon(Icons.bookmark, size: 18, color: Colors.white),
            if (isWeekly) const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  /// Builds a save button that saves selected route/time if both are selected
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: (selectedRouteIndex != null && selectedTimeIndex != null)
          ? _saveDailySchedule
          : null, // Disabled if selection incomplete
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        disabledBackgroundColor: Colors.grey,
      ),
      child: const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  /// Saves a new schedule if it doesn't already exist
  void _saveDailySchedule() {
    final newRoute = routes[selectedRouteIndex!];
    final newTime = times[selectedTimeIndex!];

    // Check for duplicate
    final isDuplicate = savedSchedules.any(
      (s) => s['route'] == newRoute && s['time'] == newTime,
    );

    if (isDuplicate) {
      // Show feedback if already saved
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This combination already exists')),
      );
      return;
    }

    // Save new schedule and reset selections
    setState(() {
      savedSchedules.add({'route': newRoute, 'time': newTime});
      selectedRouteIndex = null;
      selectedTimeIndex = null;
    });
  }

  /// Calculates the position of the tooltip based on index
  Offset _calculateTooltipPosition(BuildContext context, int index) {
    // Determines approximate x, y coordinates for tooltip
    final double y = 320.0 + (index ~/ 3) * 40.0;
    final double x = 16.0 + (index % 3) * 44.0;
    return Offset(x, y);
  }
}
