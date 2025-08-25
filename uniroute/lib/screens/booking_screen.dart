import 'package:flutter/material.dart';
import '../widgets/time_selector.dart';
import '../widgets/route_selector.dart';
import '../widgets/reminder_selector.dart';
import '../widgets/schedule_list.dart';
import '../routes.dart';
import '../widgets/app_bottom_nav_bar.dart';

/// Screen for booking new bus schedules
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? selectedRoute;
  String? selectedTime;
  int reminderHour = 0;
  int reminderMinute = 0;
  final List<Map<String, dynamic>> savedSchedules = [];

  /// Saves the current booking
  void saveSchedule() {
    if (selectedRoute != null && selectedTime != null) {
      final exists = savedSchedules.any((s) => 
        s['route'] == selectedRoute && s['time'] == selectedTime);
      
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This route and time is already booked!')));
        return;
      }

      setState(() {
        savedSchedules.add({
          'route': selectedRoute,
          'time': selectedTime,
          'hour': reminderHour,
          'minute': reminderMinute,
        });
        selectedRoute = null;
        selectedTime = null;
        reminderHour = 0;
        reminderMinute = 0;
      });
    }
  }

  /// Deletes a booked schedule
  void deleteSchedule(int index) => setState(() => savedSchedules.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Booking', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Static tab navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _tabButton(context, 'Today', true), // Current screen
                _tabButton(context, 'Weekly', false),
                _tabButton(context, 'Schedule', false),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  RouteSelector(
                    selectedRoute: selectedRoute,
                    onSelect: (route) => setState(() => selectedRoute = route),
                  ),
                  const SizedBox(height: 20),
                  TimeSelector(
                    selectedTime: selectedTime,
                    onSelect: (time) => setState(() => selectedTime = time),
                  ),
                  const SizedBox(height: 20),
                  ReminderSelector(
                    onHourChanged: (h) => setState(() => reminderHour = h),
                    onMinuteChanged: (m) => setState(() => reminderMinute = m),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: saveSchedule,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.black,
                    ),
                    child: const Text('Save'),
                  ),
                  if (savedSchedules.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Booked', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ScheduleList(
                      schedules: savedSchedules,
                      onDelete: deleteSchedule,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  /// Reusable tab button widget
  Widget _tabButton(BuildContext context, String text, bool isSelected) {
    return Flexible(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            switch (text) {
              case 'Today':
                Navigator.pushReplacementNamed(context, Routes.booking);
                break;
              case 'Weekly':
                Navigator.pushReplacementNamed(context, Routes.weekly);
                break;
              case 'Schedule':
                Navigator.pushReplacementNamed(context, Routes.schedule);
                break;
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 3,
                color: isSelected ? Colors.blue : Colors.transparent,
              ),
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}