import 'package:flutter/material.dart';
import '../screens/driver/emergency_page.dart';

class EmergencyButton extends StatelessWidget {
  /// Allows dynamic spacing from the bottom — default is 4
  final double bottomSpacing;

  const EmergencyButton({super.key, this.bottomSpacing = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + bottomSpacing,
        top: 4,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.65, // 65% width
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyPage()),
              );
            },
            icon: Image.asset(
              'assets/images/emergency_icon.png',
              width: 24,
              height: 24,
            ),
            label: const Text("EMERGENCY"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 196, 7, 7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 6,
              shadowColor: Colors.black38,
            ),
          ),
        ),
      ),
    );
  }
}
