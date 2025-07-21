import 'package:flutter/material.dart';
import '../screens/weekly_schedule_screen.dart';

/// A widget that displays a header and a button to navigate to the weekly schedule screen.
class WeeklyBookingSection extends StatelessWidget {
  const WeeklyBookingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start horizontally
      children: [
        _buildHeader(), // Custom header widget
        const SizedBox(height: 24), // Space between header and button
        ElevatedButton(
          onPressed: () {
            // Navigate to WeeklyScheduleScreen when button is pressed
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WeeklyScheduleScreen()),
            );
          },

          // Styling the button
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700], // Dark blue background color
            padding: const EdgeInsets.symmetric(vertical: 16), // Vertical padding inside button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
          ),

          // Button content: text centered horizontally
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Weekly Schedule",
                style: TextStyle(color: Colors.white, fontSize: 16), // White text
              ),
              SizedBox(width: 8), // Extra space (could be placeholder for icon if added)
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the header widget shown above the button.
  Widget _buildHeader() {
    return Align(
      alignment: Alignment.centerLeft, // Align header to the left
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Inner padding
        decoration: BoxDecoration(
          color: const Color.fromARGB(171, 61, 61, 61), // Semi-transparent dark gray background
          borderRadius: BorderRadius.circular(24), // Rounded edges for pill shape
          border: Border.all(color: Colors.black), // Black border outline
        ),

        // Row containing an icon and text label
        child: Row(
          mainAxisSize: MainAxisSize.min, // Wrap content horizontally
          children: const [
            Icon(Icons.bookmark, size: 18, color: Colors.white), // White bookmark icon
            SizedBox(width: 6), // Spacing between icon and text
            Text(
              "Weekly Booking",
              style: TextStyle(color: Colors.white, fontSize: 14), // White text
            ),
          ],
        ),
      ),
    );
  }
}

