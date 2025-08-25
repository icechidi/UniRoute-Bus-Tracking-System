import 'package:flutter/material.dart';
import '../widgets/schedule_widget.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../routes.dart';

/// Screen that displays bus schedules and allows filtering by route
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String? selectedRoute;
  
  // Mock data for route schedules
 final Map<String, List<Map<String, dynamic>>> routeSchedules = {
    'Gonyeli - Yenikent': [
      {'name': 'GAU ALKOVY CAMPUS', 'time': '11:41 | 11:43 | 11:45'},
      {'name': 'Ademari Market', 'time': '11:46 | 11:48 | 11:49'},
    ],
    'Lefkoşa - Honda': [
      {'name': 'Honda Showroom', 'time': '10:00 | 10:15 | 10:30'},
    ],
    'Lefkoşa - Hamitköy': [
      {'name': 'Hamitköy Central', 'time': '09:00 | 09:20 | 09:40'},
    ],
    'Lefkoşa - Hastane': [
      {'name': 'Hastane Main Stop', 'time': '12:00 | 12:20 | 12:40'},
    ],
    'Güzelyurt': [
      {'name': 'Güzelyurt Center', 'time': '13:00 | 13:15 | 13:30'},
    ],
    'Girne': [
      {'name': 'Girne Port', 'time': '14:00 | 14:15 | 14:30'},
    ],
  };

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
        title: const Text('Schedule', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Static tab navigation that remains visible when scrolling
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _tabButton(context, 'Today', false),
                _tabButton(context, 'Weekly', false),
                _tabButton(context, 'Schedule', true), // Current screen
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Route filter buttons
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: routeSchedules.keys.map(_routeButton).toList(),
                  ),

                  // Clear filter button (visible when a route is selected)
                  if (selectedRoute != null) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => selectedRoute = null),
                        child: const Text('Clear Filter', style: TextStyle(color: Colors.blue)),
                      ),
                    ),
                  ],

                  // Schedule content
                  if (selectedRoute != null)
                    ScheduleList(schedules: routeSchedules[selectedRoute] ?? [])
                  else
                    ...routeSchedules.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          ScheduleList(schedules: entry.value),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  /// Builds a tab button for navigation between screens
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

  /// Builds a route filter button
  Widget _routeButton(String route) {
    final isSelected = selectedRoute == route;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
      onPressed: () => setState(() => selectedRoute = route),
      child: Text(route, style: const TextStyle(color: Colors.white)),
    );
  }
}