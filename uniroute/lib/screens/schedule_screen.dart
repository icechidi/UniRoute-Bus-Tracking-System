import 'package:flutter/material.dart';
import '../widgets/selection_chips.dart';
import '../widgets/saved_schedules_visual.dart';
import '../widgets/weekly_booking_section.dart';
import '../widgets/schedule_tooltips_widget.dart';

/// Main schedule screen that allows users to:
/// - Select route and time
/// - Save them as a pair
/// - View saved schedules
/// - Tap on a calendar icon to view route/time popup only (no text shown)
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<String> routes = [
    "Gönyeli",
    "Lefkoşa - Hamitköy",
    "Lefkoşa - Honda",
    "Grine",
    "Güzelyurt",
    "Lefkoşa - Hastane",
  ];

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

  int? selectedRouteIndex;
  int? selectedTimeIndex;
  List<Map<String, String>> savedSchedules = [];

  int? tappedScheduleIndex; // index of tapped calendar icon

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Schedule", style: TextStyle(color: Colors.black)),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Hide popup when tapping outside
          if (tappedScheduleIndex != null) {
            setState(() => tappedScheduleIndex = null);
          }
        },
        child: Stack(
          children: [
            ListView(
              children: [
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

                const Text("Daily", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),

                // Visual display with calendar icon, route, and time, with delete option on tap
                Wrap(
                  spacing: 12,
                  children: List.generate(savedSchedules.length, (index) {
                    final schedule = savedSchedules[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          tappedScheduleIndex = tappedScheduleIndex == index ? null : index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12), // Add top and bottom margin
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Column(
                                children: [
                                  const Icon(Icons.calendar_month, size: 28),
                                  Text(
                                    schedule['route'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    schedule['time'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (tappedScheduleIndex == index)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      setState(() {
                                        savedSchedules.removeAt(index);
                                        tappedScheduleIndex = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.delete, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                _buildSaveButton(),
                const SizedBox(height: 24),

                WeeklyBookingSection(),
              ],
            ),

            // No tooltip popup
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(171, 61, 61, 61),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: (selectedRouteIndex != null && selectedTimeIndex != null)
          ? _saveDailySchedule
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        disabledBackgroundColor: Colors.grey,
      ),
      child: const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  void _saveDailySchedule() {
    final newRoute = routes[selectedRouteIndex!];
    final newTime = times[selectedTimeIndex!];

    final isDuplicate =
        savedSchedules.any((s) => s['route'] == newRoute && s['time'] == newTime);

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This combination already exists')),
      );
      return;
    }

    setState(() {
      savedSchedules.add({'route': newRoute, 'time': newTime});
      selectedRouteIndex = null;
      selectedTimeIndex = null;
    });
  }

}

