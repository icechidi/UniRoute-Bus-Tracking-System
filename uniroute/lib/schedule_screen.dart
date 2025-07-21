import 'package:flutter/material.dart';

void main() {
  // Run the app starting with ScheduleScreen as the home widget
  runApp(const MaterialApp(
    home: ScheduleScreen(),
    debugShowCheckedModeBanner: false, // Hide debug banner
  ));
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Currently selected route (initially set to "Güzelyurt")
  String? selectedRoute = "Güzelyurt";

  // Currently selected time
  String? selectedTime;

  // List holding all saved bookings as maps with keys "route" and "time"
  List<Map<String, String>> bookings = [];

  // Flag to show/hide the calendar icons representing bookings
  bool showBookingsIcons = false;

  // OverlayEntry instance to show tooltip overlays
  OverlayEntry? _overlayEntry;

  // List of daily available times to select from
  final dailyTimes = [
    "7:45",
    "9:45",
    "11:45",
    "12:45",
    "13:45",
    "15:45",
    "17:30",
    "20:00"
  ];

  // Method to show an overlay tooltip near the booking icon
  void _showOverlay(
      BuildContext context, Map<String, String> booking, GlobalKey iconKey) {
    // Remove any existing overlay first
    _removeOverlay();

    // Get the position of the icon on screen to position the overlay correctly
    final renderBox = iconKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    // Create the overlay entry widget
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Full screen transparent layer to detect taps outside overlay and dismiss it
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // The actual tooltip container positioned near the icon
          Positioned(
            left: offset.dx - 20, // Slightly adjust horizontal position
            top: offset.dy - 80,  // Place above the icon
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Tooltip box with route and time details
                Container(
                  width: 100,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking["route"] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking["time"] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                // Positioned delete button at top-right corner of tooltip
                Positioned(
                  top: -10,
                  right: -10,
                  child: GestureDetector(
                    onTap: () {
                      // On delete tap, remove booking from list and update UI
                      setState(() {
                        bookings.remove(booking);
                        showBookingsIcons = bookings.isNotEmpty;
                      });
                      _removeOverlay(); // Close overlay after deletion
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.delete,
                        size: 24,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Insert the overlay into the Overlay widget tree
    Overlay.of(context).insert(_overlayEntry!);
  }

  // Remove the overlay if present
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    // Ensure overlay is removed when widget is disposed
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text('Schedule', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0, // Remove shadow under app bar
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            _buildTabTitle("Route"), // Section header for routes
            const SizedBox(height: 12),
            // Display route selection chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildRouteChip("Gönyeli"),
                _buildRouteChip("Lefkoşa - Hamitköy"),
                _buildRouteChip("Lefkoşa - Honda"),
                _buildRouteChip("Grine"),
                _buildRouteChip("Güzelyurt"),
                _buildRouteChip("Lefkoşa - Hastane"),
              ],
            ),
            const SizedBox(height: 20),
            _buildTabTitle("Daily"), // Section header for daily times
            const SizedBox(height: 12),
            // Display time selection chips for daily times
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: dailyTimes.map(_buildTimeChip).toList(),
            ),
            const SizedBox(height: 20),
            // Show calendar icons representing saved bookings if any
            if (showBookingsIcons && bookings.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 20,
                children: bookings.map((booking) {
                  final iconKey = GlobalKey();
                  return GestureDetector(
                    onTap: () {
                      // Toggle the tooltip overlay on tap
                      if (_overlayEntry != null) {
                        _removeOverlay();
                      } else {
                        _showOverlay(context, booking, iconKey);
                      }
                    },
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        // Booking icon with assigned key for position
                        Icon(Icons.calendar_month,
                            key: iconKey, color: Colors.black),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                // Check if both route and time are selected before saving
                if (selectedRoute == null || selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select route & time')),
                  );
                  return;
                }

                final newBooking = {
                  "route": selectedRoute!,
                  "time": selectedTime!
                };

                // Add new booking only if it's not a duplicate
                if (!bookings.any((b) =>
                    b["route"] == newBooking["route"] &&
                    b["time"] == newBooking["time"])) {
                  bookings.add(newBooking);
                }

                setState(() {
                  // Reset selections after saving
                  selectedRoute = null;
                  selectedTime = null;
                  showBookingsIcons = true; // Show booking icons after adding
                });

                // Notify user booking saved
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking saved')),
                );
              },
              child: const Text(
                "Save",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            _buildTabTitle("Weekly", icon: Icons.bookmark_border), // Weekly section header
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                // Placeholder for "Select Booking" button action
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Select Booking",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 12,
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Set second item as selected by default
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false, // Hide labels
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }

  // Helper method to build section headers with optional icon
  Widget _buildTabTitle(String text, {IconData? icon}) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[800], // Dark grey background
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            children: [
              if (icon != null) Icon(icon, size: 18, color: Colors.white),
              if (icon != null) const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget to build each route chip button
  Widget _buildRouteChip(String label) {
    final isSelected = selectedRoute == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRoute = label; // Update selected route
          selectedTime = null; // Reset time selection when route changes
        });
      },
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? Colors.black : Colors.grey[200],
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // Widget to build each time chip button
  Widget _buildTimeChip(String time) {
    final isSelected = selectedTime == time;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTime = time; // Update selected time
        });
      },
      child: Chip(
        label: Text(time),
        backgroundColor: isSelected ? Colors.black : Colors.grey[200],
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
