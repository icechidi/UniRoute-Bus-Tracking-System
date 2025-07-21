import 'package:flutter/material.dart';

/// A bottom sheet widget that displays different content based on the provided [type].
/// If [type] is 'location', it shows a list of location entries.
/// Otherwise, it shows a placeholder for notifications.
class LocationBottomSheet extends StatelessWidget {
  /// The type of content to display (e.g., 'location' or something else).
  final String type;

  /// Constructor for the LocationBottomSheet.
  const LocationBottomSheet({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Adds padding inside the container and sets a fixed height.
      padding: const EdgeInsets.all(16),
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // If the type is 'location', display location-related UI.
          if (type == 'location') ...[
            Row(
              children: const [
                // Icon indicating GPS or fixed location.
                Icon(Icons.gps_fixed, color: Colors.black),

                // Space between the icon and the text.
                SizedBox(width: 8),

                // Title indicating current location info.
                Text(
                  'Current Location Bus',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // Divider line between title and list of locations.
            const Divider(),

            // List of hardcoded location entries.
            const ListTile(
              leading: Icon(Icons.location_on, color: Colors.red),
              title: Text("Durumcu Baba - Gonyeli"),
            ),
            const ListTile(
              leading: Icon(Icons.location_on, color: Colors.red),
              title: Text("Yalcin Park - Gonyeli"),
            ),

          // If the type is anything else, display a placeholder message.
          ] else ...[
            const Text('Notifications will be listed here.')
          ]
        ],
      ),
    );
  }
}
