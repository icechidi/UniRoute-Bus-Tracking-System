// lib/screens/driver_profile_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../widgets/emergency_button.dart';
import 'notification_settings_page.dart';
import '../language_selection_page.dart';
import 'driver_login_screen.dart';
import 'edit_profile_page.dart';
import '../../auth_services.dart';

class DriverProfilePage extends StatefulWidget {
  /// Accepts the user object (Map) passed from the login/home flow.
  /// If null is passed, the page will attempt to load the stored user and call /me.
  final Map<String, dynamic>? driver;
  final VoidCallback onBack;

  const DriverProfilePage({
    super.key,
    required this.driver,
    required this.onBack,
  });

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  bool isDarkMode = false;
  bool _isLoading = false;
  Map<String, dynamic>? _driverData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initDriverData();
    // don't await here; spinner/pull-to-refresh will reflect loading
    _tryRefreshFromServer();
  }

  Future<void> _initDriverData() async {
    // Prefer explicitly passed driver
    if (widget.driver != null && widget.driver!.isNotEmpty) {
      _driverData = Map<String, dynamic>.from(widget.driver!);
      setState(() {});
      return;
    }

    // fallback to stored user in SharedPreferences
    try {
      final stored = await AuthServices.getSavedUser();
      if (stored != null) {
        _driverData = Map<String, dynamic>.from(stored);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Failed to load stored user: $e');
    }
  }

  Future<void> _tryRefreshFromServer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Build a token-based "me" endpoint from loginUrl.
      // Adjust path below if your backend exposes a different route (e.g. /api/users/me).
      final loginUri = Uri.parse(AuthServices.loginUrl);
      final meUri = Uri(
        scheme: loginUri.scheme,
        host: loginUri.host,
        port: loginUri.hasPort ? loginUri.port : null,
        path: '/api/auth/me',
      );

      final headers = await AuthServices.authHeaders();
      final resp = await http.get(meUri, headers: headers);

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);

        // Accept either { user: { ... } } or { ...user fields... }
        Map<String, dynamic>? user;
        if (body is Map && body['user'] is Map) {
          user = Map<String, dynamic>.from(body['user']);
        } else if (body is Map) {
          user = Map<String, dynamic>.from(body);
        }

        if (user != null) {
          setState(() => _driverData = user);

          // update stored user if keepSignedIn was enabled
          try {
            final keep = await AuthServices.shouldKeepSignedIn();
            await AuthServices.saveAuthData(
                await AuthServices.getStoredToken(), user, null, keep);
          } catch (_) {
            // best-effort; ignore
          }
        } else {
          setState(() => _error = 'Unable to parse profile response.');
        }
      } else if (resp.statusCode == 401) {
        // token invalid/expired
        setState(() => _error = 'Unauthorized. Please sign in again.');
      } else {
        setState(
            () => _error = 'Failed to refresh profile (${resp.statusCode}).');
      }
    } catch (e) {
      debugPrint('Profile refresh error: $e');
      setState(() => _error = 'Error refreshing profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pullToRefresh() async {
    await _tryRefreshFromServer();
  }

  PreferredSizeWidget _buildMobileAppBar(
      BuildContext context, Color textColor, Color? backgroundColor) {
    return AppBar(
      title: Text(
        'Settings',
        style: GoogleFonts.poppins(
          fontSize: 20,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: backgroundColor,
      centerTitle: true,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: textColor),
        onPressed: widget.onBack,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: textColor),
          onPressed: _tryRefreshFromServer,
          tooltip: 'Refresh profile',
        ),
      ],
    );
  }

  Widget _buildMobileProfileSection(BuildContext context, Color textColor) {
    final displayName = _displayName();
    final email = _driverData?['email'] ?? 'No email available';
    final avatar = _driverData?['avatar_url'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : const AssetImage('assets/images/profile.png')
                    as ImageProvider,
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfilePage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDarkModeToggle(Color textColor, Color? tileColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Material(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          title: Text(
            'Dark mode',
            style: GoogleFonts.poppins(fontSize: 16, color: textColor),
          ),
          leading: Icon(Icons.nightlight_round, color: textColor),
          trailing: Switch(
            value: isDarkMode,
            onChanged: (value) => setState(() => isDarkMode = value),
            activeColor: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTile(BuildContext context, IconData icon, String title,
      {Color? color,
      required Color textColor,
      required Color? tileColor,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Material(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: color ?? textColor),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: color ?? textColor,
              fontWeight:
                  title == 'LOG OUT' ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          trailing: title == 'LOG OUT'
              ? null
              : Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
        ),
      ),
    );
  }

  Widget _buildMobileSaveButton(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings saved successfully!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Text(
            'Save',
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildWebHeader(Color textColor) {
    final displayName = _displayName();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Driver Settings',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh profile',
              onPressed: _tryRefreshFromServer,
              icon: const Icon(Icons.refresh),
              color: textColor,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$displayName — Manage your driver account preferences and application settings',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildWebProfileCard(BuildContext context, Color textColor,
      Color? cardColor, Color? borderColor) {
    final avatar = _driverData?['avatar_url'] as String?;
    final email = _driverData?['email'] ?? 'No email available';
    final phone = _driverData?['phone'] ?? '';

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Profile',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: avatar != null && avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : const AssetImage('assets/images/profile.png')
                          as ImageProvider,
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(height: 16),
                Text(
                  _displayName(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    phone,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(driver: _driverData),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebAccountCard(BuildContext context, Color textColor,
      Color? cardColor, Color? borderColor) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildWebTile(
              Icons.nightlight_round,
              'Dark Mode',
              'Switch between light and dark themes',
              textColor,
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) => setState(() => isDarkMode = value),
                activeColor: Colors.black,
              ),
            ),
            const Divider(height: 32),
            _buildWebTile(
              Icons.logout,
              'Sign Out',
              'Log out of your driver account',
              Colors.red,
              onTap: () async {
                await _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebPreferencesCard(BuildContext context, Color textColor,
      Color? cardColor, Color? borderColor) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildWebTile(
              Icons.notifications_outlined,
              'Notifications',
              'Manage your notification preferences',
              textColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsPage(),
                  ),
                );
              },
            ),
            const Divider(height: 32),
            _buildWebTile(
              Icons.language_outlined,
              'Language',
              'Change your preferred language',
              textColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LanguageSelectionPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSupportCard(BuildContext context, Color textColor,
      Color? cardColor, Color? borderColor) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildWebTile(
              Icons.support_agent_outlined,
              'Help & Support',
              'Get help and contact support',
              textColor,
              onTap: () {},
            ),
            const Divider(height: 32),
            _buildWebTile(
              Icons.info_outline,
              'Terms & Policies',
              'View terms of service and privacy policy',
              textColor,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebTile(
    IconData icon,
    String title,
    String subtitle,
    Color textColor, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: textColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textColor.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebActionButtons(BuildContext context, Color textColor) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(color: textColor.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings saved successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Save Changes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Confirm Sign Out',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to sign out of your driver account?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthServices.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverLoginScreen(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  String _displayName() {
    final first = _driverData?['first_name'] as String?;
    final last = _driverData?['last_name'] as String?;
    final username = _driverData?['username'] as String?;
    final email = _driverData?['email'] as String?;
    if (first != null && first.isNotEmpty) {
      if (last != null && last.isNotEmpty) return '$first $last';
      return first;
    }
    if (username != null && username.isNotEmpty) return username;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Unknown Driver';
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    // Check if we're on a large screen (web/tablet)
    final isLargeScreen = MediaQuery.of(context).size.width > 768;

    return WillPopScope(
      onWillPop: () async {
        widget.onBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: isLargeScreen
            ? null
            : _buildMobileAppBar(context, textColor, backgroundColor),
        body: isLargeScreen
            ? _buildWebLayout(context, textColor, isDarkMode)
            : RefreshIndicator(
                onRefresh: _pullToRefresh,
                child: _buildMobileLayout(context, textColor, isDarkMode),
              ),
      ),
    );
  }

  Widget _buildWebLayout(
      BuildContext context, Color textColor, bool isDarkMode) {
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWebHeader(textColor),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildWebProfileCard(
                            context, textColor, cardColor, borderColor),
                        const SizedBox(height: 24),
                        _buildWebAccountCard(
                            context, textColor, cardColor, borderColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildWebPreferencesCard(
                            context, textColor, cardColor, borderColor),
                        const SizedBox(height: 24),
                        _buildWebSupportCard(
                            context, textColor, cardColor, borderColor),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildWebActionButtons(context, textColor),
              const SizedBox(height: 24),
              const Center(child: EmergencyButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, Color textColor, bool isDarkMode) {
    final tileColor = isDarkMode ? Colors.grey[800] : Colors.grey.shade100;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildMobileProfileSection(context, textColor),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(
                            color: Colors.red, fontSize: 13),
                      ),
                    ),
                  _buildMobileTile(context, Icons.notifications, 'Notification',
                      textColor: textColor, tileColor: tileColor, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsPage(),
                      ),
                    );
                  }),
                  _buildMobileTile(context, Icons.language, 'Language / Dil',
                      textColor: textColor, tileColor: tileColor, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LanguageSelectionPage(),
                      ),
                    );
                  }),
                  _buildMobileDarkModeToggle(textColor, tileColor),
                  _buildMobileTile(
                      context, Icons.support_agent, 'Help & Support',
                      textColor: textColor, tileColor: tileColor, onTap: () {}),
                  _buildMobileTile(
                      context, Icons.info_outline, 'Terms and Policies',
                      textColor: textColor, tileColor: tileColor, onTap: () {}),
                  _buildMobileTile(context, Icons.logout, 'LOG OUT',
                      color: Colors.red,
                      textColor: textColor,
                      tileColor: tileColor, onTap: () async {
                    await _showLogoutDialog(context);
                  }),
                ],
              ),
            ),
            _buildMobileSaveButton(textColor),
            const EmergencyButton(),
          ],
        ),
      ),
    );
  }
}
