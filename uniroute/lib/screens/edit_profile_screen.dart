// edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/user_service.dart';
import 'change_password_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? profileImageUrl;
  String studentId = '';
  bool _loading = true;
  String? _errorMessage;
  File? _pickedImage;

  // ImageKit configuration - Replace with your actual keys
  static const String imageKitUploadUrl =
      'https://upload.imagekit.io/api/v1/files/upload';
// 🔑 Replace with your ImageKit public API key
  static const String imageKitPrivateKey =
      'private_GO4+4EVo/JO2nP9uQimZhNVqG+Q='; // 🔑 Replace with your ImageKit private API key

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'No authenticated user found';
          _loading = false;
        });
        return;
      }

      // Set email from Auth
      emailController.text = user.email ?? '';
      phoneController.text = _formatPhoneNumber(user.phoneNumber);

      // Load profile image from Auth
      setState(() {
        profileImageUrl =
            user.photoURL ?? 'assets/images/profile_placeholder.jpg';
      });

      // Load Firestore data using email as document ID
      final userData = await UserService.getUserProfile(user.email);
      if (userData != null) {
        setState(() {
          firstNameController.text = userData['first_name'] ?? '';
          lastNameController.text = userData['last_name'] ?? '';
          usernameController.text = userData['username'] ?? '';
          studentId = userData['student_id'] ?? '';
          phoneController.text = _formatPhoneNumber(userData['phone']);
          profileImageUrl = userData['photo_url'] ?? profileImageUrl;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _formatPhoneNumber(String? number) {
    if (number == null) return '';
    if (number.startsWith('+90')) return number.substring(3);
    if (number.startsWith('90')) return number.substring(2);
    return number;
  }

  Future<void> _pickAndUploadToImageKit() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => _loading = true);
    _pickedImage = File(picked.path);

    final bytes = await picked.readAsBytes();
    final base64Image = base64Encode(bytes);

    try {
      final response = await http.post(
        Uri.parse(imageKitUploadUrl),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$imageKitPrivateKey:'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'file': 'data:image/jpeg;base64,$base64Image',
          'fileName': 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          'folder': '/profiles', // Optional: organize images in folders
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final uploadedUrl = data['url'];

        setState(() {
          profileImageUrl = uploadedUrl;
        });

        final user = FirebaseAuth.instance.currentUser;
        await user?.updatePhotoURL(uploadedUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile image updated successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('ImageKit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image upload failed: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _loading) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Update Firebase Auth display name
      final displayName =
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
              .trim();
      if (displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      // Prepare phone number with country code
      final phoneWithCode = phoneController.text.trim().isNotEmpty
          ? '+90${phoneController.text.trim()}'
          : '';

      // Use UserService to update profile
      final success = await UserService.createOrUpdateUserProfile(
        email: user.email!,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        username: usernameController.text.trim(),
        phone: phoneWithCode,
        photoURL: profileImageUrl,
        displayName: displayName,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile updated successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception("Failed to save profile");
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // White background color scheme
    const backgroundColor = Colors.white;
    const cardColor = Colors.white;
    const textColor = Colors.black;
    final borderColor = Colors.grey[300];

    if (_loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.black),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: GoogleFonts.poppins(color: textColor),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading data',
                style: GoogleFonts.poppins(
                  textStyle: Theme.of(context).textTheme.headlineSmall,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Text('Retry', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero, // Remove default padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            _buildHeaderCard(cardColor, textColor, borderColor),
            // Form content with padding
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildFormFields(cardColor, textColor, borderColor),
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

            Color.fromARGB(255, 109, 165, 248), // Dark purple
            Color.fromARGB(255, 62, 30, 247), 
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
                  onTap: _pickAndUploadToImageKit,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (profileImageUrl != null &&
                                  profileImageUrl!.startsWith('http'))
                              ? NetworkImage(profileImageUrl!)
                              : const AssetImage(
                                      'assets/images/profile_placeholder.jpg')
                                  as ImageProvider,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: _pickAndUploadToImageKit,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
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
                color: Colors.white.withValues(alpha: 0.9),
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
              _buildSectionTitle('Student ID', textColor),
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
          color: textColor.withValues(alpha: 0.5),
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
          color: textColor.withValues(alpha: 0.7),
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
                  size: 16, color: textColor.withValues(alpha: 0.7)),
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
                color: textColor.withValues(alpha: 0.5),
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
            color: Colors.black.withValues(alpha: 0.1),
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
          color: textColor.withValues(alpha: 0.7),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangePasswordScreen(),
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
