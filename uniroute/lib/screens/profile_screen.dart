import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/user_service.dart';
import '../screens/student_login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _countryController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: isError ? Colors.red[100] : Colors.white,
          ),
        ),
        backgroundColor: isError ? Colors.red[800] : Colors.black,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _deleteAccount(String password) async {
    try {
      if (!mounted) return false;
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('No authenticated user found', isError: true);
        return false;
      }

      try {
        if (user.providerData.any((info) => info.providerId == 'password')) {
          final cred = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
          await user.reauthenticateWithCredential(cred);
        }

        final profileDeleted = await UserService.deleteUserProfile();
        if (!profileDeleted) {
          _showSnack('Failed to delete profile data', isError: true);
          return false;
        }

        await user.delete();
        await FirebaseAuth.instance.signOut();

        return true;
      } on FirebaseAuthException catch (e) {
        debugPrint('Account deletion error: ${e.code} - ${e.message}');
        String errorMessage = 'Account deletion failed';

        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Incorrect password';
            break;
          case 'requires-recent-login':
            errorMessage = 'Session expired. Please log in again.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many attempts. Try again later.';
            break;
          default:
            errorMessage = 'Error: ${e.message ?? e.code}';
        }

        _showSnack(errorMessage, isError: true);
        return false;
      } catch (e) {
        debugPrint('Unexpected error during deletion: $e');
        _showSnack('Account deletion failed', isError: true);
        return false;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Delete Account',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'This action cannot be undone. All your data will be permanently deleted.',
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    enabled: !isLoading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.withOpacity(0.5),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (passwordController.text.isEmpty) {
                            _showSnack('Please enter your password',
                                isError: true);
                            return;
                          }

                          setState(() => isLoading = true);
                          final success = await _deleteAccount(
                              passwordController.text.trim());
                          setState(() => isLoading = false);

                          if (success && mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const StudentLoginScreen()),
                              (route) => false,
                            );
                            _showSnack('Account deleted successfully');
                          }
                        },
                  child: Text(
                    'Delete',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUsernameDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Change your username',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You can only change your username once every 30 days.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: GoogleFonts.poppins(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: GoogleFonts.poppins(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final updated =
                    await UserService.updateUsername(_usernameController.text);
                _showSnack(
                    updated ? 'Username Updated' : 'Username not available',
                    isError: !updated);
              },
              child: Text('Done', style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  void _showPhoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Update Phone Number',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A verification code will be sent to this number.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 12),
            IntlPhoneField(
              initialValue: _phoneController.text,
              onChanged: (phone) {
                _phoneController.text = phone.completeNumber;
              },
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSnack('Phone Number Updated');
              },
              child: Text('Verify', style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: UserService.getUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No profile data found"));
          }

          final userData = snapshot.data!;
          final fullName = UserService.getFullName(userData);
          final names = fullName.split(' ');

          // Initialize controllers with user data
          _studentIdController.text = userData['student_id'] ?? '';
          _usernameController.text = userData['username'] ?? '';
          _firstNameController.text = names.isNotEmpty ? names[0] : '';
          _lastNameController.text =
              names.length > 1 ? names.sublist(1).join(' ') : '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _countryController.text = userData['country'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student ID
                _buildLabel('Student ID'),
                _buildTextField(_studentIdController, enabled: false),
                const SizedBox(height: 16),

                // Username
                _buildLabel('Username'),
                _buildTextField(_usernameController),
                const SizedBox(height: 16),

                // First Name and Last Name (side by side)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('First Name'),
                          _buildTextField(_firstNameController),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Last Name'),
                          _buildTextField(_lastNameController),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email
                _buildLabel('Email'),
                _buildTextField(_emailController, enabled: false),
                const SizedBox(height: 16),

                // Password
                _buildLabel('Password'),
                _buildTextField(
                  _passwordController,
                  obscureText: true,
                  hintText: 'Enter new password',
                ),
                const SizedBox(height: 16),

                // Phone Number
                _buildLabel('Phone Number'),
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: _inputDecoration(),
                  initialCountryCode: 'TR',
                  onChanged: (phone) {
                    _phoneController.text = phone.completeNumber;
                  },
                ),
                const SizedBox(height: 16),

                // Country
                _buildLabel('Country'),
                _buildTextField(_countryController),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _saveProfile,
                    child: Text(
                      'SAVE CHANGES',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Security Section
                _sectionHeader('Security'),
                _actionButton('Change Password'),
                _actionButton('Delete Account',
                    isDestructive: true,
                    onTap: () => _showDeleteAccountDialog()),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller,
      {bool enabled = true, bool obscureText = false, String? hintText}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      decoration: _inputDecoration(hintText: hintText),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black.withOpacity(0.8), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _actionButton(String label,
      {bool isDestructive = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isDestructive ? Colors.red : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoading = true);

      final success = await UserService.updateUserFields({
        'username': _usernameController.text,
        'phone': _phoneController.text,
        'country': _countryController.text,
      });

      _showSnack(success ? 'Profile Saved' : 'Failed to save',
          isError: !success);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildBottomNav() => BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        onTap: (index) {},
      );
}
