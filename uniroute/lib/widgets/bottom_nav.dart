import 'package:flutter/material.dart';

/// A reusable bottom navigation bar widget used across multiple screens.
/// 
/// Displays three icons:
/// - Location
/// - Calendar with a red notification badge (hardcoded to '5')
/// - Profile
class BottomNav extends StatelessWidget {
  final int currentIndex; // The currently selected index
  final void Function(int) onTap; // Callback when a navigation item is tapped

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex, // Highlight the selected item
      onTap: onTap, // Trigger the callback on tap
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
      items: [
        // Location tab
        const BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: '',
        ),

        // Calendar tab with a notification badge (e.g., for 5 upcoming events)
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
                  child: const Text(
                    '5',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          label: '',
        ),

        // Profile tab
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: '',
        ),
      ],
    );
  }
}

