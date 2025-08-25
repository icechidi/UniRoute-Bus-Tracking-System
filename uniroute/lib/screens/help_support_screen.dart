// help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final isLargeScreen = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: isLargeScreen
          ? null
          : AppBar(
              title: Text(
                'Help & Support',
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
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: isLargeScreen
          ? _buildWebLayout(context, textColor, cardColor, borderColor)
          : _buildMobileLayout(context, textColor, cardColor, borderColor),
    );
  }

  Widget _buildWebLayout(BuildContext context, Color textColor,
      Color? cardColor, Color? borderColor) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(textColor),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildFAQCard(textColor, cardColor, borderColor),
                        const SizedBox(height: 24),
                        _buildContactCard(textColor, cardColor, borderColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildQuickActionsCard(
                            textColor, cardColor, borderColor),
                        const SizedBox(height: 24),
                        _buildResourcesCard(textColor, cardColor, borderColor),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Color textColor,
      Color? cardColor, Color? borderColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFAQCard(textColor, cardColor, borderColor),
            const SizedBox(height: 16),
            _buildContactCard(textColor, cardColor, borderColor),
            const SizedBox(height: 16),
            _buildQuickActionsCard(textColor, cardColor, borderColor),
            const SizedBox(height: 16),
            _buildResourcesCard(textColor, cardColor, borderColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help & Support',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get help with your account and find answers to common questions',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFAQCard(Color textColor, Color? cardColor, Color? borderColor) {
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
            Row(
              children: [
                Icon(Icons.help_outline, color: textColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Frequently Asked Questions',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFAQItem(
              'How do I reset my password?',
              'Go to the login screen and tap "Forgot Password". Enter your email address and follow the instructions sent to your email.',
              textColor,
            ),
            const Divider(height: 24),
            _buildFAQItem(
              'How do I update my profile information?',
              'Navigate to Settings > Profile and tap the "Edit Profile" button. Make your changes and save.',
              textColor,
            ),
            const Divider(height: 24),
            _buildFAQItem(
              'How do I report a missing item?',
              'Go to Settings > Missing Item and fill out the form with details about your lost item.',
              textColor,
            ),
            const Divider(height: 24),
            _buildFAQItem(
              'How do I change my notification settings?',
              'Go to Settings > Notifications and toggle the settings according to your preferences.',
              textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, Color textColor) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      iconColor: textColor,
      collapsedIconColor: textColor,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Text(
            answer,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(
      Color textColor, Color? cardColor, Color? borderColor) {
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
            Row(
              children: [
                Icon(Icons.contact_support, color: textColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Contact Us',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildContactItem(
              Icons.email_outlined,
              'Email Support',
              'support@yourapp.com',
              textColor,
              onTap: () => _launchEmail('support@yourapp.com'),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              Icons.phone_outlined,
              'Phone Support',
              '+1 (555) 123-4567',
              textColor,
              onTap: () => _launchPhone('+15551234567'),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              Icons.chat_outlined,
              'Live Chat',
              'Available 24/7',
              textColor,
              onTap: () => _showChatDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String title,
    String subtitle,
    Color textColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
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
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: textColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(
      Color textColor, Color? cardColor, Color? borderColor) {
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
            Row(
              children: [
                Icon(Icons.flash_on, color: textColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              'Report a Bug',
              Icons.bug_report_outlined,
              textColor,
              onTap: () => _showBugReportDialog(),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Feature Request',
              Icons.lightbulb_outline,
              textColor,
              onTap: () => _showFeatureRequestDialog(),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Account Issues',
              Icons.account_circle_outlined,
              textColor,
              onTap: () => _showAccountIssuesDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesCard(
      Color textColor, Color? cardColor, Color? borderColor) {
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
            Row(
              children: [
                Icon(Icons.library_books, color: textColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Resources',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildResourceItem(
              'User Guide',
              'Complete guide to using the app',
              Icons.menu_book,
              textColor,
              onTap: () => _launchURL('https://yourapp.com/guide'),
            ),
            const SizedBox(height: 16),
            _buildResourceItem(
              'Video Tutorials',
              'Step-by-step video instructions',
              Icons.play_circle_outline,
              textColor,
              onTap: () => _launchURL('https://yourapp.com/tutorials'),
            ),
            const SizedBox(height: 16),
            _buildResourceItem(
              'Community Forum',
              'Connect with other users',
              Icons.forum,
              textColor,
              onTap: () => _launchURL('https://yourapp.com/forum'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color textColor, {
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(title),
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: textColor.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildResourceItem(
    String title,
    String subtitle,
    IconData icon,
    Color textColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
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
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: textColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for actions
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showChatDialog() {
    // Implement chat dialog or redirect to chat service
  }

  void _showBugReportDialog() {
    // Implement bug report dialog
  }

  void _showFeatureRequestDialog() {
    // Implement feature request dialog
  }

  void _showAccountIssuesDialog() {
    // Implement account issues dialog
  }
}
