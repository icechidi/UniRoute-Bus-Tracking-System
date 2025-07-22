import 'package:flutter/material.dart';
import 'active_trip_page.dart';
import '../widgets/emergency_button.dart';
import '../widgets/bottom_nav_bar.dart';
import 'main_screen.dart';

class PreTripPage extends StatelessWidget {
  final String route;
  final String time;
  final String busId;

  const PreTripPage({
    super.key,
    required this.route,
    required this.time,
    required this.busId,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Bus'), centerTitle: true),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.directions_bus, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                _infoBox('BUS'),
                const SizedBox(height: 30),
                Text('ROUTE - $route', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                Text('TIME - $time', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                Text(busId, style: const TextStyle(fontSize: 20)),
              ],
            ),
            Column(
              children: [
                _infoBox('START TRIP'),
                const SizedBox(height: 10),
                const Text(
                  'Tap the button to begin',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActiveTripPage(
                            route: route,
                            time: time,
                            busId: busId,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'START TRIP',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            const EmergencyButton(),
          ],
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: 0,
          onTabSelected: (index) {
            if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainScreen(initialIndex: 1),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _infoBox(String label) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
