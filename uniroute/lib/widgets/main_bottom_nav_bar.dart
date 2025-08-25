import 'package:flutter/material.dart';
//import '../routes.dart';

class MainBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const MainBottomNavBar({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
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
