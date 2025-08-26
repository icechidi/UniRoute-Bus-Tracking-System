import 'package:flutter/material.dart';
import '../../widgets/emergency_button.dart';
import '../../widgets/universal_app_bar.dart';

class ActiveTripPage extends StatelessWidget {
  final String route;
  final String time;
  final String busId;
  final VoidCallback onStopTrip;
  final VoidCallback onProfileTap;
  final VoidCallback onBack;

  const ActiveTripPage({
    super.key,
    required this.route,
    required this.time,
    required this.busId,
    required this.onStopTrip,
    required this.onProfileTap,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: UniversalAppBar(
          title: 'Bus',
          showBack: true,
          onBack: onBack,
          onProfileTap: onProfileTap,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ROUTE - $route',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Time – $time'),
                          Text('Bus ID: $busId'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    GestureDetector(
                      onTap: () {
                        print("⏸ Stop Trip button tapped");
                        onStopTrip();
                      },
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.pause,
                          color: Colors.white,
                          size: 70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'STOP TRIP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 23, 221, 30),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Tap the button to stop'),
                  ],
                ),
              ),
            ),
            const EmergencyButton(bottomSpacing: 0),
          ],
        ),
      ),
    );
  }
}
