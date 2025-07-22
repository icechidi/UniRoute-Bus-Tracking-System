import 'package:flutter/material.dart';
import 'driver_login_page.dart';
import '../widgets/emergency_button.dart';
import 'main_screen.dart';

class DriverProfilePage extends StatelessWidget {
  final String driverName;

  const DriverProfilePage({super.key, required this.driverName});

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
        appBar: AppBar(title: const Text('Settings')),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'USER NAME',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(driverName, style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildSettingItem(
                    title: 'Notification',
                    icon: Icons.notifications,
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildSettingItem(
                    title: 'Language / Dil',
                    icon: Icons.language,
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildSettingItem(
                    title: 'Theme',
                    icon: Icons.color_lens,
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildSettingItem(
                    title: 'Support',
                    icon: Icons.support_agent,
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildSettingItem(
                    title: 'About',
                    icon: Icons.info,
                    onTap: () => _showComingSoon(context),
                  ),
                  const Divider(height: 20),
                  _buildSettingItem(
                    title: 'LOG OUT',
                    icon: Icons.logout,
                    color: Colors.red,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
            const EmergencyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    Color color = Colors.black,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DriverLoginPage()),
      (route) => false,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feature coming soon!')));
  }
}
