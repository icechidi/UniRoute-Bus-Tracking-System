import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/user_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isEmailNotificationsEnabled = true;
  bool _isPushNotificationsEnabled = true;
  bool _isLoading = false;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _fetchNotificationSettings();
  }

  Future<void> _fetchNotificationSettings() async {
    if (mounted) setState(() => _isInitialLoad = true);

    try {
      final fetchedData = await UserService.fetchNotificationSettings();
      if (mounted) {
        setState(() {
          _isEmailNotificationsEnabled = fetchedData['isEmailEnabled'] ?? false;
          _isPushNotificationsEnabled = fetchedData['isPushEnabled'] ?? false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoad = false);
        _showSnackBar('Failed to load notification settings.');
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final success = await UserService.saveNotificationSettings(
        isEmailEnabled: _isEmailNotificationsEnabled,
        isPushEnabled: _isPushNotificationsEnabled,
      );

      if (mounted) {
        if (success) {
          _showSnackBar('Notification settings saved!', isError: false);
        } else {
          _showSnackBar('Failed to save notification settings.');
        }
      }
    } catch (_) {
      if (mounted) _showSnackBar('Failed to save notification settings.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // White background with black primary color scheme
    const backgroundColor = Colors.white;
    final cardColor = Colors.grey[50];
    const textColor = Colors.black87;
    final borderColor = Colors.grey[200];
    const primaryColor = Colors.black;

    // Check if we're on a large screen (web/tablet)
    final isLargeScreen = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isInitialLoad
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchNotificationSettings,
              color: primaryColor,
              backgroundColor: Colors.white,
              child: isLargeScreen
                  ? _buildWebLayout(
                      cardColor, textColor, borderColor, primaryColor)
                  : _buildMobileLayout(
                      cardColor, textColor, borderColor, primaryColor),
            ),
    );
  }

  Widget _buildMobileLayout(Color? cardColor, Color textColor,
      Color? borderColor, Color primaryColor) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(cardColor, textColor, borderColor, primaryColor),
          const SizedBox(height: 20),
          _buildNotificationSettings(
              cardColor, textColor, borderColor, primaryColor),
          const SizedBox(height: 30),
          _buildSaveButton(primaryColor),
        ],
      ),
    );
  }

  Widget _buildWebLayout(Color? cardColor, Color textColor, Color? borderColor,
      Color primaryColor) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(cardColor, textColor, borderColor, primaryColor),
              const SizedBox(height: 32),
              _buildNotificationSettings(
                  cardColor, textColor, borderColor, primaryColor),
              const SizedBox(height: 40),
              _buildSaveButton(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color? cardColor, Color textColor, Color? borderColor,
      Color primaryColor) {
    return Card(
      color: cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Preferences',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage how you receive notifications and updates',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings(Color? cardColor, Color textColor,
      Color? borderColor, Color primaryColor) {
    return Card(
      color: cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Types',
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildNotificationTile(
              title: 'Email Notifications',
              subtitle: 'Receive updates via email',
              icon: Icons.email_outlined,
              value: _isEmailNotificationsEnabled,
              onChanged: (bool value) {
                setState(() => _isEmailNotificationsEnabled = value);
              },
              textColor: textColor,
              borderColor: borderColor,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 16),
            _buildNotificationTile(
              title: 'Push Notifications',
              subtitle: 'Receive instant push notifications',
              icon: Icons.notifications_outlined,
              value: _isPushNotificationsEnabled,
              onChanged: (bool value) {
                setState(() => _isPushNotificationsEnabled = value);
              },
              textColor: textColor,
              borderColor: borderColor,
              primaryColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color? borderColor,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor!, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: primaryColor,
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveNotificationSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[500],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Save Settings',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
