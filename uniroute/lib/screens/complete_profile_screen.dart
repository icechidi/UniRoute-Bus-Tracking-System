import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../widgets/common_widgets.dart';
import 'success_screen.dart';

// Data model for better type safety
class ProfileData {
  final String firstName;
  final String lastName;
  final String username;
  final String country;
  final String studentId;
  final String phone;

  const ProfileData({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.country,
    required this.studentId,
    required this.phone,
  });

  bool get isValid =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      username.isNotEmpty &&
      country.isNotEmpty &&
      studentId.isNotEmpty &&
      phone.isNotEmpty;
}

// Validation result for better error handling
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;
}

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _countryController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // State variables
  String? _phoneNumberWithCountryCode;
  bool _isSubmitting = false;
  String? _studentIdError;
  List<String> _usernameSuggestions = [];
  Timer? _usernameDebounce;
  Country? _selectedCountry;

  // Constants
  static const int _studentIdLength = 8;
  static const String _studentIdPrefix = '3';
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  static const int _maxUsernameSuggestions = 3;
  static const int _minUsernameLength = 3;

  @override
  void dispose() {
    _disposeControllers();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  void _disposeControllers() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _countryController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
  }

  // Validation methods
  ValidationResult _validateStudentId(String value) {
    if (value.isEmpty) {
      return const ValidationResult.valid();
    }

    if (value.length != _studentIdLength) {
      return ValidationResult.invalid("student_id_must_be_8_digits".tr());
    }

    if (!value.startsWith(_studentIdPrefix)) {
      return ValidationResult.invalid("student_id_must_start_with_3".tr());
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return ValidationResult.invalid("student_id_numbers_only".tr());
    }

    return const ValidationResult.valid();
  }

  void _onStudentIdChanged(String value) {
    final result = _validateStudentId(value);
    setState(() {
      _studentIdError = result.errorMessage;
    });
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ${"is_required".tr()}';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "username_required".tr();
    }
    if (value.trim().length < _minUsernameLength) {
      return "username_min_length".tr();
    }
    return null;
  }

  // Profile data extraction
  ProfileData _getProfileData() {
    return ProfileData(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim().toLowerCase(),
      country: _countryController.text.trim(),
      studentId: _studentIdController.text.trim(),
      phone: _phoneNumberWithCountryCode ?? '',
    );
  }

  // Username generation methods
  List<String> _generateUsernameCandidates(
      String base, String first, String last) {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch % 1000;

    return [
      base,
      '$base$timestamp',
      '$first$last',
      '$first.$last',
      '$last$first',
      '$base${100 + random.nextInt(900)}',
      '$first${100 + random.nextInt(900)}',
      '${base}_${100 + random.nextInt(900)}',
      '$first${last.isNotEmpty ? last[0] : ''}${100 + random.nextInt(900)}',
      '${first.isNotEmpty ? first[0] : ''}$last${100 + random.nextInt(900)}',
    ].where((s) => s.length >= _minUsernameLength).toSet().toList();
  }

  Future<bool> _isUsernameAvailable(String username) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      return false;
    }
  }

  Future<void> _generateUsernameSuggestions(String input) async {
    if (!mounted) return;

    final suggestions = <String>[];
    final first = _firstNameController.text.trim().toLowerCase();
    final last = _lastNameController.text.trim().toLowerCase();
    final base = input.toLowerCase();

    final candidates = _generateUsernameCandidates(base, first, last);

    for (final candidate in candidates) {
      if (suggestions.length >= _maxUsernameSuggestions) break;

      if (await _isUsernameAvailable(candidate)) {
        suggestions.add(candidate);
      }
    }

    if (mounted) {
      setState(() {
        _usernameSuggestions = suggestions;
      });
    }
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();

    if (value.trim().length > _minUsernameLength) {
      _usernameDebounce = Timer(_debounceDelay, () {
        _generateUsernameSuggestions(value.trim());
      });
    } else {
      setState(() {
        _usernameSuggestions = [];
      });
    }
  }

  void _selectUsernameSuggestion(String suggestion) {
    _usernameController.text = suggestion;
    setState(() {
      _usernameSuggestions = [];
    });
  }

  // Authentication and user validation
  Future<User?> _validateCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showErrorSnackBar('user_not_logged_in'.tr());
      return null;
    }

    if (!user.emailVerified) {
      _showErrorSnackBar('email_not_verified_error'.tr());
      return null;
    }

    return user;
  }

  // Profile submission
  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = await _validateCurrentUser();
    if (user?.email == null) return;

    final profileData = _getProfileData();
    if (!profileData.isValid) {
      _showErrorSnackBar('fields_required'.tr());
      return;
    }

    final studentIdValidation = _validateStudentId(profileData.studentId);
    if (!studentIdValidation.isValid) {
      _showErrorSnackBar(studentIdValidation.errorMessage!);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Check username availability one final time
      if (!await _isUsernameAvailable(profileData.username)) {
        _showErrorSnackBar('username_taken_suggestions'.tr());
        return;
      }

      await _updateUserProfile(user!.email!, profileData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      _showErrorSnackBar('failed_to_update_profile'.tr());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateUserProfile(String email, ProfileData profileData) async {
    await FirebaseFirestore.instance.collection('users').doc(email).update({
      'first_name': profileData.firstName,
      'last_name': profileData.lastName,
      'username': profileData.username,
      'country': profileData.country,
      'student_id': profileData.studentId,
      'phone': profileData.phone,
      'email_status': 'verified',
      'account_status': 'complete',
      'profile_completed_at': FieldValue.serverTimestamp(),
    });
  }

  // UI helper methods
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
          _countryController.text = country.name;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "tell_us_about_yourself".tr(),
      subtitle: "complete_profile_subtitle".tr(),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNameFields(),
              const SizedBox(height: 16),
              _buildUsernameField(),
              _buildUsernameSuggestions(),
              const SizedBox(height: 16),
              _buildCountryField(),
              const SizedBox(height: 16),
              _buildStudentIdField(),
              const SizedBox(height: 16),
              _buildPhoneField(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _firstNameController,
            decoration: buildInputDecoration('first_name'.tr()),
            textCapitalization: TextCapitalization.words,
            validator: (value) => _validateRequired(value, 'first_name'.tr()),
            enabled: !_isSubmitting,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _lastNameController,
            decoration: buildInputDecoration('last_name'.tr()),
            textCapitalization: TextCapitalization.words,
            validator: (value) => _validateRequired(value, 'last_name'.tr()),
            enabled: !_isSubmitting,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: buildInputDecoration('username'.tr()).copyWith(),
      validator: _validateUsername,
      onChanged: _onUsernameChanged,
      enabled: !_isSubmitting,
    );
  }

  Widget _buildUsernameSuggestions() {
    if (_usernameSuggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'username_suggestions'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _usernameSuggestions.map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              onPressed: () => _selectUsernameSuggestion(suggestion),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCountryField() {
    return TextFormField(
      controller: _countryController,
      decoration: buildInputDecoration('country'.tr()).copyWith(
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      readOnly: true,
      onTap: _showCountryPicker,
      validator: (value) => _validateRequired(value, 'country'.tr()),
      enabled: !_isSubmitting,
    );
  }

  Widget _buildStudentIdField() {
    return TextFormField(
      controller: _studentIdController,
      decoration: buildInputDecoration('student_id'.tr()).copyWith(
        errorText: _studentIdError,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(_studentIdLength),
      ],
      onChanged: _onStudentIdChanged,
      validator: (value) {
        final result = _validateStudentId(value ?? '');
        return result.isValid ? null : result.errorMessage;
      },
      enabled: !_isSubmitting,
    );
  }

  Widget _buildPhoneField() {
    return IntlPhoneField(
      controller: _phoneController,
      decoration: buildInputDecoration('phone_number'.tr()),
      initialCountryCode: _selectedCountry?.countryCode ?? 'US',
      onChanged: (phone) {
        _phoneNumberWithCountryCode = phone.completeNumber;
      },
      validator: (phone) {
        if (phone == null || phone.number.isEmpty) {
          return 'phone_required'.tr();
        }
        return null;
      },
      enabled: !_isSubmitting,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 1.5),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text('complete_profile'.tr()),
      ),
    );
  }
}
