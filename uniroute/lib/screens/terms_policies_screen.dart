// terms_policies_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsPoliciesScreen extends StatefulWidget {
  const TermsPoliciesScreen({super.key});

  @override
  State<TermsPoliciesScreen> createState() => _TermsPoliciesScreenState();
}

class _TermsPoliciesScreenState extends State<TermsPoliciesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 768;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Terms & Policies',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: textColor,
          unselectedLabelColor: textColor.withValues(alpha: 0.6),
          indicatorColor: Colors.black,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Terms of Service'),
            Tab(text: 'Privacy Policy'),
            Tab(text: 'Cookie Policy'),
          ],
        ),
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: isLargeScreen
                ? 1400
                : double.infinity, // Increased from 1000 to 1400
          ),
          margin: EdgeInsets.symmetric(
            horizontal:
                isLargeScreen ? 24 : 0, // Reduced margin for wider content
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTermsOfService(textColor, cardColor, borderColor),
              _buildPrivacyPolicy(textColor, cardColor, borderColor),
              _buildCookiePolicy(textColor, cardColor, borderColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsOfService(
      Color textColor, Color? cardColor, Color? borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12), // Reduced padding for more width
      child: Card(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32, // Increased horizontal padding
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                '1. Acceptance of Terms',
                'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.',
                textColor,
              ),
              _buildSection(
                '2. Use License',
                'Permission is granted to temporarily download one copy of the materials on our application for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• modify or copy the materials\n• use the materials for any commercial purpose or for any public display\n• attempt to reverse engineer any software contained in the application\n• remove any copyright or other proprietary notations from the materials',
                textColor,
              ),
              _buildSection(
                '3. Disclaimer',
                'The materials on our application are provided on an \'as is\' basis. We make no warranties, expressed or implied, and hereby disclaim and negate all other warranties including without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
                textColor,
              ),
              _buildSection(
                '4. Limitations',
                'In no event shall our company or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on our application, even if we or our authorized representative has been notified orally or in writing of the possibility of such damage.',
                textColor,
              ),
              _buildSection(
                '5. Account Terms',
                'You are responsible for safeguarding the password and for maintaining the confidentiality of your account. You are fully responsible for all activities that occur under your account.',
                textColor,
              ),
              _buildSection(
                '6. Prohibited Uses',
                'You may not use our service:\n\n• for any unlawful purpose or to solicit others to perform unlawful acts\n• to violate any international, federal, provincial, or state regulations, rules, laws, or local ordinances\n• to infringe upon or violate our intellectual property rights or the intellectual property rights of others\n• to harass, abuse, insult, harm, defame, slander, disparage, intimidate, or discriminate\n• to submit false or misleading information',
                textColor,
              ),
              _buildSection(
                '7. Termination',
                'We may terminate or suspend your account and bar access to the service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms.',
                textColor,
              ),
              _buildSection(
                '8. Changes to Terms',
                'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect.',
                textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicy(
      Color textColor, Color? cardColor, Color? borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12), // Reduced padding for more width
      child: Card(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32, // Increased horizontal padding
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Information We Collect',
                'We collect information you provide directly to us, such as when you create an account, update your profile, or contact us for support. This may include:\n\n• Name and email address\n• Profile information\n• Communications with us\n• Usage data and analytics',
                textColor,
              ),
              _buildSection(
                'How We Use Your Information',
                'We use the information we collect to:\n\n• Provide, maintain, and improve our services\n• Process transactions and send related information\n• Send technical notices and support messages\n• Respond to your comments and questions\n• Monitor and analyze trends and usage',
                textColor,
              ),
              _buildSection(
                'Information Sharing',
                'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy. We may share your information:\n\n• With service providers who assist us in operating our application\n• To comply with legal obligations\n• To protect our rights and safety',
                textColor,
              ),
              _buildSection(
                'Data Security',
                'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
                textColor,
              ),
              _buildSection(
                'Data Retention',
                'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this policy, unless a longer retention period is required by law.',
                textColor,
              ),
              _buildSection(
                'Your Rights',
                'You have the right to:\n\n• Access your personal information\n• Correct inaccurate information\n• Delete your personal information\n• Object to processing of your information\n• Data portability',
                textColor,
              ),
              _buildSection(
                'Children\'s Privacy',
                'Our service is not intended for children under 13. We do not knowingly collect personal information from children under 13. If we become aware that a child under 13 has provided us with personal information, we will delete such information.',
                textColor,
              ),
              _buildSection(
                'Changes to Privacy Policy',
                'We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page and updating the "Last updated" date.',
                textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCookiePolicy(
      Color textColor, Color? cardColor, Color? borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12), // Reduced padding for more width
      child: Card(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32, // Increased horizontal padding
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cookie Policy',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                'What Are Cookies',
                'Cookies are small text files that are placed on your device when you visit our application. They help us provide you with a better experience by remembering your preferences and understanding how you use our service.',
                textColor,
              ),
              _buildSection(
                'Types of Cookies We Use',
                'Essential Cookies: These are necessary for the application to function properly and cannot be disabled.\n\nAnalytical Cookies: These help us understand how visitors interact with our application by collecting and reporting information anonymously.\n\nFunctional Cookies: These enable enhanced functionality and personalization, such as remembering your preferences.\n\nAdvertising Cookies: These may be set through our site by advertising partners to build a profile of your interests.',
                textColor,
              ),
              _buildSection(
                'How We Use Cookies',
                'We use cookies to:\n\n• Keep you signed in\n• Remember your preferences\n• Analyze how our application is used\n• Improve our services\n• Provide personalized content',
                textColor,
              ),
              _buildSection(
                'Managing Cookies',
                'You can control and manage cookies in various ways. Please note that removing or blocking cookies can impact your user experience and parts of our application may no longer be fully accessible.',
                textColor,
              ),
              _buildSection(
                'Third-Party Cookies',
                'We may use third-party services that place cookies on your device. These services have their own privacy policies and cookie policies, which we encourage you to review.',
                textColor,
              ),
              _buildSection(
                'Updates to Cookie Policy',
                'We may update this cookie policy from time to time to reflect changes in our practices or for other operational, legal, or regulatory reasons.',
                textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
