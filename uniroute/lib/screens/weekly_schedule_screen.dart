import 'package:flutter/material.dart';
import '../widgets/day_schedule_row.dart';
import '../widgets/schedule_tooltips_widget.dart';
import '../widgets/selection_bottom_sheet.dart';
import '../widgets/bottom_nav.dart';
import 'map_screen.dart';
import 'schedule_screen.dart';

/// Screen that allows users to plan and manage a weekly transportation schedule.
class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  // Predefined list of possible addresses (routes)
  final List<String> addresses = [
    "Adamar Market", "Durumcu Baba - Gonyeli", "Yalcin Park - Gonyeli",
    "The Hane - Gonyeli", "Big Kiler Market - Gonyeli",
    "Gonyeli Municipality - Yenikent", "Molto Market / China Bazaar - Ortakoy",
  ];

  // Predefined list of selectable times
  final List<String> times = [
    "7:45", "9:45", "11:45", "12:45", "13:45", "15:45", "17:30"
  ];

  // Stores schedule for each day; key = day, value = list of route/time maps
  final Map<String, List<Map<String, String>>> weeklySchedule = {};

  String? selectedDay;                 // Day currently being modified
  String? tempSelectedRoute;           // Temporarily selected route during entry creation
  Offset? tooltipOffset;              // Screen position for showing tooltip
  Map<String, String>? hoveredSchedule; // Currently hovered entry for tooltip
  String? hoveredDay;                  // Day associated with the hovered schedule

  /// Opens the address picker bottom sheet for the selected day
  void _openAddressPicker(String day) {
    selectedDay = day;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => SelectionBottomSheet(
        title: "Select Your Address",
        items: addresses,
        onSelected: (value) {
          tempSelectedRoute = value;
          Navigator.pop(context); // Close address picker
          _openTimePicker(day);   // Open time picker
        },
      ),
    );
  }

  /// Opens the time picker bottom sheet for the selected day
  void _openTimePicker(String day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => SelectionBottomSheet(
        title: "Select Your Time",
        items: times,
        onSelected: (value) {
          if (tempSelectedRoute == null) return;

          final entry = {'route': tempSelectedRoute!, 'time': value};
          final existing = weeklySchedule[day] ?? [];

          // Check for duplicates before saving
          final isDuplicate = existing.any((e) =>
              e['route'] == entry['route'] && e['time'] == entry['time']);

          if (!isDuplicate) {
            setState(() {
              weeklySchedule[day] = [...existing, entry];
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("This route & time already exists for this day")),
            );
          }

          tempSelectedRoute = null;
          Navigator.pop(context); // Close time picker
        },
      ),
    );
  }

  /// Removes a selected schedule entry from a specific day
  void _deleteSchedule(String day, Map<String, String> schedule) {
    setState(() {
      weeklySchedule[day]?.remove(schedule);
      hoveredSchedule = null; // Hide tooltip
    });
  }

  /// Handles taps on the bottom navigation bar
  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScheduleScreen()));
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text("User Profile")),
              body: const Center(child: Text("User Profile Details Here")),
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Weekday labels
    final weekDays = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY"];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 32),
          onPressed: () => Navigator.pop(context), // Back button
        ),
        title: const Text("Weekly", style: TextStyle(color: Colors.black)),
      ),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => setState(() => hoveredSchedule = null),
            child: Column(
              children: [
                // Booking header
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [Icon(Icons.calendar_month, size: 16), SizedBox(width: 6), Text("Booking")],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Day rows for each weekday
                ...weekDays.map((day) => DayScheduleRow(
                      day: day,
                      entries: weeklySchedule[day] ?? [],
                      onAdd: () => _openAddressPicker(day),
                      onTapEntry: (entry, details) {
                        setState(() {
                          hoveredSchedule = entry;
                          hoveredDay = day;
                          tooltipOffset = details.globalPosition; // Store position for tooltip
                        });
                      },
                    )),

                const Spacer(),

                // Save button (currently no functionality)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Save", style: TextStyle(color: Colors.white)),
                  ),
                ),

                // Bottom navigation bar
                BottomNav(currentIndex: 1, onTap: _onBottomNavTapped),
              ],
            ),
          ),

          // Tooltip overlay when a schedule entry is hovered
          if (hoveredSchedule != null && tooltipOffset != null)
            ScheduleTooltipWidget(
              schedule: hoveredSchedule!,
              position: tooltipOffset!,
              onDelete: () => _deleteSchedule(hoveredDay!, hoveredSchedule!),
            ),
        ],
      ),
    );
  }
}

