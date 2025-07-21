import 'package:flutter/material.dart';
import 'weekly_schedule.dart'; // Make sure this file exists

/// Main schedule screen that allows users to:
/// 1. Select routes and times for daily bookings
/// 2. View saved schedules
/// 3. Navigate to weekly booking screen
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
  int? hoveredScheduleIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 32),
          onPressed: () {
            Navigator.pop(context);
          },
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
                _buildSectionHeader("Route"),
                const SizedBox(height: 24),
                _buildSelectionChips(routes, selectedRouteIndex),
                const SizedBox(height: 16),
                _buildSectionHeader("Time"),
                const SizedBox(height: 24),
                _buildSelectionChips(times, selectedTimeIndex),
                const SizedBox(height: 20),
                const Text("Daily", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                _buildSavedSchedulesVisual(),
                const SizedBox(height: 24),
                _buildSaveButton(),
                const SizedBox(height: 24),
                _buildWeeklyBookingSection(),
              ],
            ),
            if (hoveredScheduleIndex != null)
              _buildScheduleTooltip(context),
          ],
        ),
      ),
    );
  }

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
            if (isWeekly) ...[
              const Icon(Icons.bookmark, size: 18, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionChips(List<String> items, int? selectedIndex) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(items.length, (index) {
        final isSelected = selectedIndex == index;
        return GestureDetector(
          onTap: () => _handleSelection(items, index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black),
            ),
            child: Text(
              items[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }),
    );
  }

  void _handleSelection(List<String> items, int index) {
    setState(() {
      if (selectedRouteIndex == index || selectedTimeIndex == index) {
        if (items == routes) {
          selectedRouteIndex = null;
        } else {
          selectedTimeIndex = null;
        }
      } else {
        if (items == routes) {
          selectedRouteIndex = index;
        } else {
          selectedTimeIndex = index;
        }
      }
    });
  }

  Widget _buildSavedSchedulesVisual() {
    return Wrap(
      spacing: 12,
      children: List.generate(savedSchedules.length, (index) {
        return MouseRegion(
          onEnter: (_) => setState(() => hoveredScheduleIndex = index),
          onExit: (_) => setState(() => hoveredScheduleIndex = null),
          child: Icon(
            Icons.calendar_month,
            size: 32,
            color: hoveredScheduleIndex == index
                ? Colors.blue
                : Colors.black,
          ),
        );
      }),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: (selectedRouteIndex != null && selectedTimeIndex != null)
          ? () => _saveDailySchedule()
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        disabledBackgroundColor: Colors.grey,
      ),
      child: const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  void _saveDailySchedule() {
    final newRoute = routes[selectedRouteIndex!];
    final newTime = times[selectedTimeIndex!];

    final isDuplicate = savedSchedules.any(
      (schedule) => schedule['route'] == newRoute && schedule['time'] == newTime,
    );

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

  Widget _buildWeeklyBookingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Weekly Booking", isWeekly: true),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WeeklyScheduleScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Text("Weekly Schedule", style: TextStyle(color: Colors.white, fontSize: 16)),
                  SizedBox(width: 8),
                  Text("", style: TextStyle(color: Colors.white, fontSize: 24)),
                ],
          ),

        ),
      ],
    );
  }

  Positioned _buildScheduleTooltip(BuildContext context) {
    return Positioned(
      left: _calculateTooltipPosition(context, hoveredScheduleIndex!).dx,
      top: _calculateTooltipPosition(context, hoveredScheduleIndex!).dy,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
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
              Text(
                'Route: ${savedSchedules[hoveredScheduleIndex!]['route']}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Time: ${savedSchedules[hoveredScheduleIndex!]['time']}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Offset _calculateTooltipPosition(BuildContext context, int index) {
    final double yPosition = 320.0 + (index ~/ 3) * 40.0;
    final double xPosition = 16.0 + (index % 3) * 44.0;
    return Offset(xPosition, yPosition);
  }
}
