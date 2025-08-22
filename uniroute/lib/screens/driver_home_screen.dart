import 'package:flutter/material.dart';
import 'driver_profile_page.dart';
import 'route_selection_page.dart';
import 'pre_trip_page.dart';
import 'active_trip_page.dart';

enum BusPage { route, preTrip, activeTrip }

class DriverHomeScreen extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic> driver; // ✅ full user object

  const DriverHomeScreen({
    super.key,
    this.initialIndex = 0,
    required this.driver,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late int _selectedIndex;
  late BusPage _busPage;
  late BusPage _previousPage;
  String? selectedRoute;
  String? selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _busPage = BusPage.route;
    _previousPage = _busPage;
  }

  void _onTabTapped(int index) {
    setState(() {
      if (index == 1) {
        _previousPage = _busPage;
      }
      _selectedIndex = index;
    });
  }

  void _goToPreTrip(String route, String time) {
    setState(() {
      selectedRoute = route;
      selectedTime = time;
      _busPage = BusPage.preTrip;
    });
  }

  void _goToActiveTrip() {
    setState(() {
      _busPage = BusPage.activeTrip;
    });
  }

  void _endTrip() {
    setState(() {
      _busPage = BusPage.preTrip;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_selectedIndex == 1) {
      bodyContent = DriverProfilePage(
        driver: widget.driver, // ✅ pass full user object
        onBack: () {
          setState(() {
            _selectedIndex = 0;
            _busPage = _previousPage;
          });
        },
      );
    } else {
      switch (_busPage) {
        case BusPage.route:
          bodyContent = RouteSelectionPage(
            onContinue: _goToPreTrip,
            onProfileTap: () {
              setState(() {
                _previousPage = _busPage;
                _selectedIndex = 1;
              });
            },
          );
          break;
        case BusPage.preTrip:
          bodyContent = PreTripPage(
            route: selectedRoute!,
            time: selectedTime!,
            busId: 'ID #4571',
            onStartTrip: _goToActiveTrip,
            onProfileTap: () {
              setState(() {
                _previousPage = _busPage;
                _selectedIndex = 1;
              });
            },
            onBack: () {
              setState(() {
                _busPage = BusPage.route;
              });
            },
          );
          break;
        case BusPage.activeTrip:
          bodyContent = ActiveTripPage(
            route: selectedRoute!,
            time: selectedTime!,
            busId: 'ID #4571',
            onStopTrip: _endTrip,
            onProfileTap: () {
              setState(() {
                _previousPage = _busPage;
                _selectedIndex = 1;
              });
            },
            onBack: () {
              setState(() {
                _busPage = BusPage.route;
              });
            },
          );
          break;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBody: true,
      body: SafeArea(
        top: false,
        child: bodyContent,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.directions_bus, 'Bus'),
              _buildNavItem(1, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.grey[800] : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.grey[800]!.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }
}
