import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'change_password_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String profileImageUrl = 'assets/images/profile.png';
  String studentId = 'admin777@domain.com';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    phoneController.text = '5335555555';
    firstNameController.text = 'Ali';
    lastNameController.text = 'Ahmed';
    usernameController.text = 'Ali AHMED';
    emailController.text = 'admin777@domain.com';
  }

  @override
  void dispose() {
    phoneController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _loading = true;
    });

    // Simulate save operation
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color.fromARGB(255, 107, 171, 255), // Red
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // White background color scheme
    const backgroundColor = Colors.white;
    const textColor = Colors.black;
    final borderColor = Colors.grey[300];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            color: const Color.fromARGB(255, 2, 0, 7),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            _buildHeaderCard(
                const Color.fromARGB(255, 248, 247, 248), textColor, borderColor),
            // Form content with padding
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildFormFields(const Color.fromARGB(255, 255, 255, 255),
                      textColor, borderColor),
                  const SizedBox(height: 30),
                  _buildSaveButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
      Color cardColor, Color textColor, Color? borderColor) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8B5CF6), // Light purple
            Color(0xFFEC4899), // Pink
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.only(top: 40, bottom: 60, left: 20, right: 20),
        child: Column(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    // Handle image picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Image picker functionality',
                          style: GoogleFonts.poppins(),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: AssetImage(profileImageUrl),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () {
                      // Handle image picker
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              usernameController.text.isNotEmpty
                  ? usernameController.text
                  : 'User Profile',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${emailController.text}${phoneController.text.isNotEmpty ? ' | +90${phoneController.text}' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields(
      Color cardColor, Color textColor, Color? borderColor) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (studentId.isNotEmpty) ...[
              _buildSectionTitle('Driver ID', textColor),
              const SizedBox(height: 8),
              _buildReadOnlyField(studentId, textColor, borderColor),
              const SizedBox(height: 20),
            ],
            _buildSectionTitle('Username', textColor),
            const SizedBox(height: 8),
            _buildTextField(
                usernameController, 'Enter username', textColor, borderColor),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('First Name', textColor),
                      const SizedBox(height: 8),
                      _buildTextField(firstNameController, 'First name',
                          textColor, borderColor),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Last Name', textColor),
                      const SizedBox(height: 8),
                      _buildTextField(lastNameController, 'Last name',
                          textColor, borderColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Email', textColor),
            const SizedBox(height: 8),
            _buildReadOnlyField(emailController.text, textColor, borderColor),
            const SizedBox(height: 20),
            _buildSectionTitle('Phone Number', textColor),
            const SizedBox(height: 8),
            _buildPhoneField(textColor, borderColor),
            const SizedBox(height: 20),
            _buildSectionTitle('Country/Region', textColor),
            const SizedBox(height: 8),
            _buildCountryDropdown(textColor, borderColor),
            const SizedBox(height: 20),
            _buildChangePasswordTile(textColor, borderColor),
            const SizedBox(height: 20),
            _buildDeleteAccountTile(textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      Color textColor, Color? borderColor) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 16, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: textColor.withOpacity(0.5),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildReadOnlyField(String text, Color textColor, Color? borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: textColor.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildPhoneField(Color textColor, Color? borderColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor!),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 14,
                decoration: const BoxDecoration(color: Colors.red),
              ),
              const SizedBox(width: 8),
              Text(
                '+90',
                style: GoogleFonts.poppins(fontSize: 16, color: textColor),
              ),
              Icon(Icons.arrow_drop_down,
                  size: 16, color: textColor.withOpacity(0.7)),
            ],
          ),
        ),
        Expanded(
          child: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.poppins(fontSize: 16, color: textColor),
            decoration: InputDecoration(
              hintText: '533555555',
              hintStyle: GoogleFonts.poppins(
                color: textColor.withOpacity(0.5),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryDropdown(Color textColor, Color? borderColor) {
    return DropdownButtonFormField<String>(
      value: 'Turkey',
      style: GoogleFonts.poppins(fontSize: 16, color: textColor),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      dropdownColor: Colors.white,
      items: ['Turkey', 'USA', 'UK', 'Germany']
          .map((country) => DropdownMenuItem(
                value: country,
                child: Text(
                  country,
                  style: GoogleFonts.poppins(color: textColor),
                ),
              ))
          .toList(),
      onChanged: (value) {},
    );
  }

  Widget _buildChangePasswordTile(Color textColor, Color? borderColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.lock_outline,
            color: Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: textColor.withOpacity(0.7),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangePasswordPage(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeleteAccountTile(Color textColor) {
    return GestureDetector(
      onTap: () {
        // Show confirmation dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Account', style: GoogleFonts.poppins()),
            content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Implement delete account logic
                },
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      child: Row(
        children: [
          const Icon(Icons.delete_outline, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Text(
            'Delete Account',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[400],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
