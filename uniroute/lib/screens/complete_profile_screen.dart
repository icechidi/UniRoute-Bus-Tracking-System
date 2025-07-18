import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../widgets/common_widgets.dart';
import 'success_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _phoneNumberWithCountryCode;
  bool _isSubmitting = false;
  String? _studentIdError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _countryController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validateStudentId(String value) {
    if (value.isEmpty) {
      setState(() => _studentIdError = null);
      return;
    }

    if (value.length != 8) {
      setState(() => _studentIdError = "student_id_must_be_8_digits".tr());
      return;
    }

    if (!value.startsWith('3')) {
      setState(() => _studentIdError = "student_id_must_start_with_3".tr());
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      setState(() => _studentIdError = "student_id_numbers_only".tr());
      return;
    }

    setState(() => _studentIdError = null);
  }

  Future<void> _submitProfile() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final country = _countryController.text.trim();
    final studentId = _studentIdController.text.trim();
    final phone = _phoneNumberWithCountryCode;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (user == null || email == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('user_not_logged_in'.tr())),
      );
      return;
    }

    if (!user.emailVerified) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('email_not_verified_error'.tr())),
      );
      return;
    }

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        username.isEmpty ||
        country.isEmpty ||
        studentId.isEmpty ||
        phone == null ||
        phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_complete_all_fields'.tr())),
      );
      return;
    }

    // Re-validate student ID in case it wasn't caught by onChanged
    _validateStudentId(studentId);
    if (_studentIdError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_studentIdError!)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final usernameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (usernameSnapshot.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('username_already_taken'.tr())),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(email).update({
        'first_name': firstName,
        'last_name': lastName,
        'username': username.toLowerCase(),
        'country': country,
        'student_id': studentId,
        'phone': phone,
        'email_status': 'verified',
        'account_status': 'complete',
        'profile_completed_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuccessScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('failed_to_update_profile'.tr())),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "tell_us_about_yourself".tr(),
      subtitle: "",
      child: Column(
        children: [
          // First Name
          TextField(
            controller: _firstNameController,
            decoration: buildInputDecoration('first_name'.tr()),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Last Name
          TextField(
            controller: _lastNameController,
            decoration: buildInputDecoration('last_name'.tr()),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Username
          TextField(
            controller: _usernameController,
            decoration: buildInputDecoration('username'.tr()),
          ),
          const SizedBox(height: 16),

          // Country picker
          GestureDetector(
            onTap: () {
              showCountryPicker(
                context: context,
                showPhoneCode: false,
                onSelect: (country) {
                  setState(() {
                    _countryController.text = country.name;
                  });
                },
              );
            },
            child: AbsorbPointer(
              child: TextField(
                controller: _countryController,
                readOnly: true,
                decoration: buildInputDecoration('country'.tr()).copyWith(
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Student ID - Removed the fixed "3" prefix
          TextField(
            controller: _studentIdController,
            decoration: buildInputDecoration('student_id'.tr()).copyWith(
              errorText: _studentIdError,
              hintText: '3XXXXXXX', // Hint instead of prefix
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            onChanged: _validateStudentId,
          ),
          const SizedBox(height: 16),

          // Phone Number
          IntlPhoneField(
            controller: _phoneController,
            decoration: buildInputDecoration('phone_number'.tr()),
            initialCountryCode: 'TR',
            onChanged: (phone) {
              setState(() {
                _phoneNumberWithCountryCode = phone.completeNumber;
              });
              _countryController.text = phone.countryISOCode;
            },
          ),
          const SizedBox(height: 32),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    )
                  : Text(
                      "continue".tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Terms and Privacy Policy
          Text.rich(
            TextSpan(
              text: "by_clicking_continue".tr(),
              style: const TextStyle(color: Colors.grey),
              children: [
                TextSpan(
                  text: "terms_of_service".tr(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Navigate to terms of service
                    },
                ),
                const TextSpan(text: " and "),
                TextSpan(
                  text: "privacy_policy".tr(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Navigate to privacy policy
                    },
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
