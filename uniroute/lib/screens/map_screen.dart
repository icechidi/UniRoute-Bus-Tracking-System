import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/location_bottom_sheet.dart';

/// A screen displaying a Google Map with a bottom navigation bar.
/// Users can view their current location, access schedule or profile screens,
/// and interact with location options via a bottom sheet.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController; // Controller to interact with the Google Map
  int _selectedIndex = 0; // Index of the currently selected navigation item

  /// Called when the Google Map is created
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Handles taps on the bottom navigation bar
  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Perform navigation based on selected index
    if (index == 0) {
      _showBottomSheet('location'); // Show bottom sheet for location options
    } else if (index == 1) {
      Navigator.pushNamed(context, '/schedule'); // Navigate to schedule screen
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile'); // Navigate to profile screen
    }
  }

  /// Displays a modal bottom sheet with location options
  void _showBottomSheet(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => LocationBottomSheet(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main content using Stack to layer map and AppBar
      body: Stack(
        children: [
          // Google Map display
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(42.3601, -71.0589), // Default location (e.g. Boston)
              zoom: 14,
            ),
            myLocationEnabled: true, // Show user's location
            zoomControlsEnabled: false, // Hide default zoom controls
          ),

          // Custom transparent AppBar over the map
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Text('Map', style: TextStyle(color: Colors.black)),
              actions: [
                // User profile picture on the right
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                    radius: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom navigation bar for Location, Schedule, and Profile
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/location_icon.png',
              width: 32,
              height: 32,
            ),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/schedule_icon.png',
              width: 32,
              height: 32,
            ),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/user_icon.png',
              width: 32,
              height: 32,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

