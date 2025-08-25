import 'package:flutter/material.dart';
import '../widgets/emergency_button.dart';
import '../widgets/universal_app_bar.dart';

class PreTripPage extends StatelessWidget {
  final String route;
  final String time;
  final String busId;
  final VoidCallback onStartTrip;
  final VoidCallback onProfileTap;
  final VoidCallback onBack;

  const PreTripPage({
    super.key,
    required this.route,
    required this.time,
    required this.busId,
    required this.onStartTrip,
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

                    // --- Start Trip Button ---
                    InkWell(
                      onTap: () {
                        print("▶️ Start Trip button tapped");
                        onStartTrip();
                      },
                      borderRadius: BorderRadius.circular(70),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0C2F3D),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'START TRIP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C2F3D),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Tap the button to begin'),
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
