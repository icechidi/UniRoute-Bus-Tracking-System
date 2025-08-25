import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15), // navbar shadow
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTabItem(
              index: 0,
              iconPath: currentIndex == 0
                  ? 'assets/images/bus_icon_active.png'
                  : 'assets/images/bus_icon_inactive.png',
              isSelected: currentIndex == 0,
            ),
            _buildTabItem(
              index: 1,
              iconPath: currentIndex == 1
                  ? 'assets/images/profile_active.png'
                  : 'assets/images/profile_inactive.png',
              isSelected: currentIndex == 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String iconPath,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[400] : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25), // more visible shadow
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(child: Image.asset(iconPath, height: 26, width: 26)),
      ),
    );
  }
}
