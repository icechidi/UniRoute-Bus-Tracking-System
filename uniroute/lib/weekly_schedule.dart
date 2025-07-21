import 'package:flutter/material.dart';
import 'package:uniroute/main.dart';
import 'package:uniroute/schedule.dart';

// Entry point of the app
void main() {
  runApp(const MaterialApp(home: WeeklyScheduleScreen()));
}

/// Placeholder page for Location
class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location")),
      body: const Center(child: Text("Location Page")),
    );
  }
}

/// Placeholder page for User Profile
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Profile")),
      body: const Center(child: Text("User Profile Page")),
    );
  }
}

/// Main Weekly Schedule Screen
class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  final List<String> addresses = [
    "Adamar Market",
    "Durumcu Baba - Gonyeli",
    "Yalcin Park - Gonyeli",
    "The Hane - Gonyeli",
    "Big Kiler Market - Gonyeli",
    "Gonyeli Municipality - Yenikent",
    "Molto Market / China Bazaar - Ortakoy",
  ];

  final List<String> times = [
    "7:45", "9:45", "11:45", "12:45", "13:45", "15:45", "17:30"
  ];

  final Map<String, List<Map<String, String>>> weeklySchedule = {};
  String? selectedDay;
  String? tempSelectedRoute;
  Offset? tooltipOffset;
  Map<String, String>? hoveredSchedule;
  String? hoveredDay;

  void _openAddressPicker(String day) {
    selectedDay = day;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(242, 255, 255, 255),
      builder: (_) => _buildBottomSheet(
        title: "Select Your Address",
        items: addresses,
        onSelected: (value) {
          tempSelectedRoute = value;
          Navigator.pop(context);
          _openTimePicker(day);
        },
      ),
    );
  }

  void _openTimePicker(String day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(242, 255, 255, 255),
      builder: (_) => _buildBottomSheet(
        title: "Select Your Time",
        items: times,
        onSelected: (value) {
          if (tempSelectedRoute == null) return;

          final entry = {'route': tempSelectedRoute!, 'time': value};
          final existing = weeklySchedule[day] ?? [];

          final isDuplicate = existing.any(
              (e) => e['route'] == entry['route'] && e['time'] == entry['time']);

          if (!isDuplicate) {
            setState(() {
              weeklySchedule[day] = [...existing, entry];
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("This route & time already exists for this day"),
            ));
          }

          tempSelectedRoute = null;
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildBottomSheet({
    required String title,
    required List<String> items,
    required void Function(String) onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close),
              )
            ],
          ),
          const Divider(),
          ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) => ListTile(
              title: Text(items[index]),
              onTap: () => onSelected(items[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(String day) {
    final entries = weeklySchedule[day] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          Text(day, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          if (entries.isEmpty)
            const Text("Select route, time",
                style: TextStyle(color: Colors.grey)),
          Wrap(
            spacing: 6,
            children: entries.map((entry) {
              return GestureDetector(
                onTapDown: (details) {
                  setState(() {
                    hoveredSchedule = entry;
                    hoveredDay = day;
                    tooltipOffset = details.globalPosition;
                  });
                },
                child: const Icon(Icons.calendar_month),
              );
            }).toList(),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAddressPicker(day),
          ),
        ],
      ),
    );
  }

  void _deleteSchedule(String day, Map<String, String> schedule) {
    setState(() {
      weeklySchedule[day]?.remove(schedule);
      hoveredSchedule = null;
    });
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MapScreen()));
        break;
      case 1:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ScheduleScreen()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UserProfilePage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY"];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(230, 255, 255, 255),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Weekly", style: TextStyle(color: Colors.black)),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            hoveredSchedule = null;
          });
        },
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, top: 8, bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.calendar_month, size: 16),
                            SizedBox(width: 6),
                            Text("Booking"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...weekDays.map(_buildDayRow),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Save",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
            if (hoveredSchedule != null && tooltipOffset != null) ...[
              Positioned.fill(
                child: Container(
                    color: const Color.fromARGB(77, 0, 0, 0)), // 0.3 * 255 = 76.5 ≈ 77
              ),
              Positioned(
                left: tooltipOffset!.dx - 100,
                top: tooltipOffset!.dy - 120,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hoveredSchedule!['route']!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                        Text(hoveredSchedule!['time']!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 18),
                            onPressed: () {
                              if (hoveredDay != null) {
                                _deleteSchedule(hoveredDay!, hoveredSchedule!);
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: _onBottomNavTapped,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.location_on), label: ''),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.calendar_today),
              Positioned(
                top: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 7,
                  backgroundColor: Colors.red,
                  child: const Text('5',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
            ],
          ),
          label: '',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: ''),
      ],
    );
  }
}

