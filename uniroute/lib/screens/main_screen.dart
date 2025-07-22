import 'package:flutter/material.dart';
import 'route_selection_page.dart';
import 'driver_profile_page.dart';
import '../widgets/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  static final List<Widget> _pages = [
    const RouteSelectionPage(),
    const DriverProfilePage(driverName: 'Driver Name'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTabSelected: _onTabTapped,
      ),
    );
  }
}
