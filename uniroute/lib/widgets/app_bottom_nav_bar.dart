import 'package:flutter/material.dart';
import '../routes.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const AppBottomNavBar({super.key, required this.currentIndex});

  void _onNavTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    if (index == 0) {
      Navigator.pushReplacementNamed(context, Routes.map);
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, Routes.booking);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, Routes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onNavTap(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/icons/location_icon.png'), size: 32),
          label: 'Location',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/icons/schedule_icon.png'), size: 32),
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/icons/user_icon.png'), size: 32),
          label: 'Profile',
        ),
      ],
    );
  }
}
