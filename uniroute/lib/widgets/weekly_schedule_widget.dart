import 'package:flutter/material.dart';
import 'reminder_selector.dart';
import 'route_selector.dart';
import 'time_selector.dart';
import 'booked_item.dart';
import '../routes.dart';
import '../widgets/app_bottom_nav_bar.dart';

class WeeklyScheduleWidget extends StatefulWidget {
  const WeeklyScheduleWidget({super.key});

  @override
  State<WeeklyScheduleWidget> createState() => _WeeklyScheduleWidgetState();
}

class _WeeklyScheduleWidgetState extends State<WeeklyScheduleWidget> {
  String? selectedRoute;
  String? selectedTime;
  Set<String> selectedDays = {};
  List<BookedItem> booked = [];
  int reminderHour = 0;
  int reminderMinute = 0;

  final List<String> days = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  void bookSchedule() {
    if (selectedRoute != null && selectedTime != null && selectedDays.isNotEmpty) {
      bool duplicate = false;

      for (var day in selectedDays) {
        if (booked.any((item) =>
            item.route == selectedRoute &&
            item.time == selectedTime &&
            item.day == day)) {
          duplicate = true;
          break;
        }
      }

      if (duplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This route, time, and day is already booked!')));
        return;
      }

      setState(() {
        for (var day in selectedDays) {
          booked.add(BookedItem(
            route: selectedRoute!,
            time: selectedTime!,
            day: day,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            enabled: true,
          ));
        }
        selectedRoute = null;
        selectedTime = null;
        selectedDays = {};
        reminderHour = 0;
        reminderMinute = 0;
      });
    }
  }

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
        title: const Text('Weekly Schedule', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _tabButton(context, 'Today', false),
                _tabButton(context, 'Weekly', true),
                _tabButton(context, 'Schedule', false),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  RouteSelector(
                    selectedRoute: selectedRoute,
                    onSelect: (val) => setState(() => selectedRoute = val),
                  ),
                  const SizedBox(height: 20),
                  TimeSelector(
                    selectedTime: selectedTime,
                    onSelect: (val) => setState(() => selectedTime = val),
                  ),
                  const SizedBox(height: 20),
                  ReminderSelector(
                    onHourChanged: (h) => setState(() => reminderHour = h),
                    onMinuteChanged: (m) => setState(() => reminderMinute = m),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Days'),
                  _buildMultiChips(days),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: bookSchedule,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.black,
                    ),
                    child: const Text("Save"),
                  ),
                  if (booked.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Booked Schedules',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: booked.map((item) {
                          return BookedItemCard(
                            item: item,
                            onDelete: () => setState(() => booked.remove(item)),
                            onToggleEnabled: (val) => setState(() => item.enabled = val),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ]),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

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

  Widget _buildMultiChips(List<String> options) {
    return Wrap(
      spacing: 10,
      children: options.map((item) {
        final isSelected = selectedDays.contains(item);
        return FilterChip(
          label: Text(item, style: const TextStyle(color: Colors.white)),
          selected: isSelected,
          selectedColor: const Color(0xFF444444),
          backgroundColor: const Color(0xFF222222),
          checkmarkColor: Colors.white,
          onSelected: (val) {
            setState(() {
              isSelected ? selectedDays.remove(item) : selectedDays.add(item);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
