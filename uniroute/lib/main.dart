import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(const BusApp());

/// Root widget of the Bus application.
/// Uses MaterialApp with custom routing configuration.
class BusApp extends StatelessWidget {
  const BusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  int _selectedIndex = 0;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _showBottomSheet(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (type == 'location') ...[
                Row(
                  children: const [
                    Icon(Icons.gps_fixed, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Current Location Bus',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.location_on, color: Colors.red),
                  title: Text("Durumcu Baba - Gonyeli"),
                ),
                const ListTile(
                  leading: Icon(Icons.location_on, color: Colors.red),
                  title: Text("Yalcin Park - Gonyeli"),
                ),
              ] else if (type == 'notifications') ...[
                const Text('Notifications will be listed here.'),
              ]
            ],
          ),
        );
      },
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) _showBottomSheet('location');
    if (index == 1) _showBottomSheet('notifications');
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(42.3601, -71.0589), // Sample location
              zoom: 14,
            ),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
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
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/images/profile.jpg'),
                    radius: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              'assets/icons/notification_icon.png',
              width: 32,
              height: 32,
            ),
            label: 'Notifications',
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
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}

// ----------------------------------
// User Profile Page
// ----------------------------------

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: const Center(child: Text('User Profile Details Here')),
    );
  }   
}
