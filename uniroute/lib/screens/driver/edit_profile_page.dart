// lib/screens/edit_profile_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../auth_services.dart';
import 'change_password_page.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? driver;

  const EditProfilePage({super.key, this.driver});

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
  String studentId = '';
  bool _loading = false;
  bool _isRefreshing = false;

  Map<String, dynamic>? _driverData;

  @override
  void initState() {
    super.initState();
    _initFromPassedOrStored();
    _tryRefreshFromServer();
  }

  Future<void> _initFromPassedOrStored() async {
    if (widget.driver != null && widget.driver!.isNotEmpty) {
      _setFromMap(widget.driver!);
      return;
    }
    try {
      final stored = await AuthServices.getSavedUser();
      if (stored != null) _setFromMap(Map<String, dynamic>.from(stored));
    } catch (e) {
      debugPrint('EditProfile: failed to load stored user: $e');
    }
  }

  void _setFromMap(Map<String, dynamic> map) {
    _driverData = Map<String, dynamic>.from(map);
    firstNameController.text = _driverData?['first_name'] ?? '';
    lastNameController.text = _driverData?['last_name'] ?? '';
    usernameController.text = _driverData?['username'] ??
        '${_driverData?['first_name'] ?? ''} ${_driverData?['last_name'] ?? ''}'
            .trim();
    emailController.text = _driverData?['email'] ?? '';
    phoneController.text = _driverData?['phone'] ?? '';
    profileImageUrl = _driverData?['avatar_url'] ?? profileImageUrl;
    studentId = _driverData?['id']?.toString() ?? _driverData?['email'] ?? '';
    if (mounted) setState(() {});
  }

  /// Fetch the user profile by user_id from /api/auth/users/:id
  Future<void> _tryRefreshFromServer() async {
    if (studentId.isEmpty) return; // ensure we have user_id
    setState(() => _isRefreshing = true);

    try {
      final loginUri = Uri.parse(AuthServices.loginUrl);
      final userUri = Uri(
        scheme: loginUri.scheme,
        host: loginUri.host,
        port: loginUri.hasPort ? loginUri.port : null,
        path: '/api/auth/users/$studentId',
      );

      final headers = await AuthServices.authHeaders();
      final resp = await http.get(userUri, headers: headers);

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        if (body is Map) _setFromMap(Map<String, dynamic>.from(body));
      } else {
        debugPrint('EditProfile refresh failed: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('EditProfile refresh error: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  /// Save changes by PUT to /api/auth/users/:id
  Future<void> _saveChanges() async {
    if (studentId.isEmpty) return;

    setState(() => _loading = true);
    try {
      final loginUri = Uri.parse(AuthServices.loginUrl);
      final userUri = Uri(
        scheme: loginUri.scheme,
        host: loginUri.host,
        port: loginUri.hasPort ? loginUri.port : null,
        path: '/api/auth/users/$studentId',
      );

      final headers = await AuthServices.authHeaders();
      headers['Content-Type'] = 'application/json';

      final body = <String, dynamic>{
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'username': usernameController.text.trim(),
        'phone': phoneController.text.trim(),
      };

      final resp =
          await http.put(userUri, headers: headers, body: json.encode(body));

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        Map<String, dynamic>? updated;
        if (resp.body.isNotEmpty) {
          final parsed = json.decode(resp.body);
          if (parsed is Map) updated = Map<String, dynamic>.from(parsed);
        }

        updated ??= (_driverData ?? {})..addAll(body);

        _setFromMap(updated);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!',
                style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile (${resp.statusCode}).',
                style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Save profile error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error saving profile: $e', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
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
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _tryRefreshFromServer,
            tooltip: 'Refresh from server',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(const Color.fromARGB(255, 248, 247, 248),
                textColor, borderColor),
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
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Image picker functionality',
                              style: GoogleFonts.poppins()),
                          behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: profileImageUrl.startsWith('http')
                          ? NetworkImage(profileImageUrl) as ImageProvider
                          : AssetImage(profileImageUrl),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () {},
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
                                offset: const Offset(0, 2))
                          ]),
                      child:
                          const Icon(Icons.edit, size: 18, color: Colors.black),
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
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '${emailController.text}${phoneController.text.isNotEmpty ? ' | +90${phoneController.text}' : ''}',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.white.withOpacity(0.9)),
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
          side: BorderSide(color: borderColor!, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildSectionTitle('First Name', textColor),
                  const SizedBox(height: 8),
                  _buildTextField(firstNameController, 'First name', textColor,
                      borderColor),
                ])),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildSectionTitle('Last Name', textColor),
                  const SizedBox(height: 8),
                  _buildTextField(
                      lastNameController, 'Last name', textColor, borderColor),
                ])),
          ]),
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
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(title,
        style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w500, color: color));
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      Color textColor, Color? borderColor) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 16, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            color: textColor.withOpacity(0.5), fontSize: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 2)),
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
          color: Colors.grey[50]),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 16, color: textColor.withOpacity(0.7))),
    );
  }

  Widget _buildPhoneField(Color textColor, Color? borderColor) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
            border: Border.all(color: borderColor!),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 20,
              height: 14,
              decoration: const BoxDecoration(color: Colors.red)),
          const SizedBox(width: 8),
          Text('+90',
              style: GoogleFonts.poppins(fontSize: 16, color: textColor)),
          Icon(Icons.arrow_drop_down,
              size: 16, color: textColor.withOpacity(0.7)),
        ]),
      ),
      Expanded(
        child: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.poppins(fontSize: 16, color: textColor),
          decoration: InputDecoration(
            hintText: '533555555',
            hintStyle: GoogleFonts.poppins(
                color: textColor.withOpacity(0.5), fontSize: 14),
            border: OutlineInputBorder(
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12)),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12)),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12)),
                borderSide: BorderSide(color: Colors.black, width: 2)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    ]);
  }

  Widget _buildCountryDropdown(Color textColor, Color? borderColor) {
    return DropdownButtonFormField<String>(
      value: 'Turkey',
      style: GoogleFonts.poppins(fontSize: 16, color: textColor),
      decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 2)),
          contentPadding: const EdgeInsets.all(16)),
      dropdownColor: Colors.white,
      items: ['Turkey', 'USA', 'UK', 'Germany']
          .map((country) => DropdownMenuItem(
              value: country,
              child:
                  Text(country, style: GoogleFonts.poppins(color: textColor))))
          .toList(),
      onChanged: (value) {},
    );
  }

  Widget _buildChangePasswordTile(Color textColor, Color? borderColor) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: borderColor!),
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child:
                const Icon(Icons.lock_outline, color: Colors.black, size: 20)),
        title: Text('Change Password',
            style: GoogleFonts.poppins(
                fontSize: 16, color: textColor, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: textColor.withOpacity(0.7)),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ChangePasswordPage())),
      ),
    );
  }

  Widget _buildDeleteAccountTile(Color textColor) {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Delete Account', style: GoogleFonts.poppins()),
                  content: Text(
                      'Are you sure you want to delete your account? This action cannot be undone.',
                      style: GoogleFonts.poppins()),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.poppins())),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context); /* implement delete */
                        },
                        child: Text('Delete',
                            style: GoogleFonts.poppins(color: Colors.red))),
                  ],
                ));
      },
      child: Row(children: [
        const Icon(Icons.delete_outline, color: Colors.red, size: 24),
        const SizedBox(width: 12),
        Text('Delete Account',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w400, color: Colors.red)),
      ]),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text('Save Changes',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
