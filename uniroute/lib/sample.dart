import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    _showBottomSheet(context);
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedIndex == 0) ...[
              const ListTile(
                leading: Icon(Icons.my_location, color: Colors.black),
                title: Text('Current Location Bus'),
              ),
              const ListTile(
                leading: Icon(Icons.location_on, color: Colors.red),
                title: Text('Durumcu Baba - Gonyeli'),
              ),
              const ListTile(
                leading: Icon(Icons.location_on, color: Colors.red),
                title: Text('Yalcin Park - Gonyeli'),
              ),
            ] else if (selectedIndex == 1) ...[
              const ListTile(
                leading: Icon(Icons.notifications, color: Colors.orange),
                title: Text('No new notifications'),
              ),
            ] else if (selectedIndex == 2) ...[
              const ListTile(
                leading: Icon(Icons.person, color: Colors.blue),
                title: Text('User Profile Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background map image
          Positioned.fill(
            child: Image.asset(
              'assets/map/maps.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Header with profile picture
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(),
                const Text(
                  'Map',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    backgroundImage: AssetImage('assets/map/maps.jpg'),
                    radius: 18,
                  ),
                ),
              ],
            ),
          ),
          // Bottom info text
          const Positioned(
            bottom: 200,
            left: 20,
            child: Text(
              'Next BusStop live...',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_pin),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
      ),
    );
  }
}
