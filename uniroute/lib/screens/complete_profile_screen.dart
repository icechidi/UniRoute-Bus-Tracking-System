// complete_profile_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

import '../widgets/common_widgets.dart';
import 'success_screen.dart';

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

  Map<String, dynamic> toFirestoreMap() => {
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'country': country,
        'student_id': studentId,
        'phone': phone,
        'email_status': 'verified',
        'account_status': 'complete',
        'profile_completed_at': FieldValue.serverTimestamp(),
      };
}

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _countryController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? _phoneNumberWithCountryCode;
  bool _isSubmitting = false;
  List<String> _usernameSuggestions = [];
  Timer? _usernameDebounce;
  Country? _selectedCountry;
  bool _isPhoneValid = false;
  String? _currentUsernameBeingChecked;

  static const int _studentIdLength = 8;
  static const String _studentIdPrefix = '3';
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  static const int _maxUsernameSuggestions = 3;
  static const int _minUsernameLength = 3;
  static const int _maxUsernameLength = 20;

  final Map<String, bool> _usernameAvailabilityCache = {};

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _countryController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  String? _validateStudentId(String? value) {
    final val = value?.trim() ?? '';
    if (val.isEmpty) return "student_id_required".tr();
    if (val.length != _studentIdLength)
      return "student_id_must_be_8_digits".tr();
    if (!val.startsWith(_studentIdPrefix))
      return "student_id_must_start_with_3".tr();
    if (!RegExp(r'^\d+$').hasMatch(val)) return "student_id_numbers_only".tr();
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty)
      return '$fieldName ${"is_required".tr()}';
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$fieldName ${"is_required".tr()}';
    if (trimmed.length < 2) return '$fieldName ${"min_length_2".tr()}';
    if (trimmed.length > 50) return '$fieldName ${"max_length_50".tr()}';
    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(trimmed))
      return '$fieldName ${"invalid_characters".tr()}';
    return null;
  }

  String? _validateUsername(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return "username_required".tr();
    if (trimmed.length < _minUsernameLength) return "username_min_length".tr();
    if (trimmed.length > _maxUsernameLength) return "username_max_length".tr();
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(trimmed))
      return "username_invalid_characters".tr();
    if (RegExp(r'[._-]{2,}').hasMatch(trimmed))
      return "username_no_consecutive_special".tr();
    if (RegExp(r'^[._-]|[._-]$').hasMatch(trimmed))
      return "username_no_special_start_end".tr();
    return null;
  }

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

  List<String> _generateUsernameCandidates(
      String base, String first, String last) {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch % 1000;
    final candidates = <String>{};

    base = _cleanUsername(base);
    first = _cleanUsername(first);
    last = _cleanUsername(last);

    if (base.isNotEmpty) {
      candidates.add(base);
      candidates.add('$base$timestamp');
      for (int i = 0; i < 2; i++) {
        final randomNum = 100 + random.nextInt(900);
        candidates.add('$base$randomNum');
        candidates.add('${base}_$randomNum');
      }
    }

    if (first.isNotEmpty && last.isNotEmpty) {
      candidates.addAll([
        '$first$last',
        '$first.$last',
        '${first}_$last',
        '$last$first',
      ]);

      final initials = '${first[0]}${last[0]}';
      for (int i = 0; i < 2; i++) {
        final randomNum = 1000 + random.nextInt(9000);
        candidates.add('$initials$randomNum');
      }
    }

    return candidates
        .where((s) =>
            s.length >= _minUsernameLength && s.length <= _maxUsernameLength)
        .where((s) => _validateUsername(s) == null)
        .toList();
  }

  String _cleanUsername(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '')
        .replaceAll(RegExp(r'[._-]{2,}'), '_')
        .replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');
  }

  Future<bool> _isUsernameAvailable(String username) async {
    final cleanUsername = username.toLowerCase().trim();

    if (_usernameAvailabilityCache.containsKey(cleanUsername)) {
      return _usernameAvailabilityCache[cleanUsername]!;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();

      final isAvailable = snapshot.docs.isEmpty;
      _usernameAvailabilityCache[cleanUsername] = isAvailable;
      return isAvailable;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      return false;
    }
  }

  Future<void> _generateUsernameSuggestions(String input) async {
    if (!mounted) return;

    final cleanInput = input.trim();
    _currentUsernameBeingChecked = cleanInput;

    final suggestions = <String>[];
    final first = _firstNameController.text.trim().toLowerCase();
    final last = _lastNameController.text.trim().toLowerCase();

    final candidates = _generateUsernameCandidates(cleanInput, first, last);
    if (candidates.isEmpty) return;

    for (final candidate in candidates.take(5)) {
      if (suggestions.length >= _maxUsernameSuggestions) break;
      if (_currentUsernameBeingChecked != cleanInput) return;

      try {
        if (await _isUsernameAvailable(candidate)) {
          suggestions.add(candidate);
        }
      } catch (e) {
        debugPrint('Error checking username $candidate: $e');
      }
    }

    if (mounted && _currentUsernameBeingChecked == cleanInput) {
      setState(() => _usernameSuggestions = suggestions);
    }
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    final trimmedValue = value.trim();

    if (trimmedValue.length >= _minUsernameLength) {
      _usernameDebounce = Timer(_debounceDelay, () {
        if (mounted) _generateUsernameSuggestions(trimmedValue);
      });
    } else {
      if (mounted) setState(() => _usernameSuggestions = []);
    }
  }

  void _selectUsernameSuggestion(String suggestion) {
    _usernameController.text = suggestion;
    FocusScope.of(context).unfocus();
    if (mounted) setState(() => _usernameSuggestions = []);
  }

  Future<User?> _validateCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar('user_not_logged_in'.tr());
      return null;
    }

    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser == null || !refreshedUser.emailVerified) {
      _showErrorSnackBar('email_not_verified_error'.tr());
      return null;
    }

    return refreshedUser;
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPhoneValid) {
      _showErrorSnackBar('phone_invalid_format'.tr());
      return;
    }

    final user = await _validateCurrentUser();
    if (user?.email == null) return;

    final profileData = _getProfileData();
    setState(() => _isSubmitting = true);

    try {
      // Final username availability check
      if (!await _isUsernameAvailable(profileData.username)) {
        _showErrorSnackBar('username_taken_suggestions'.tr());
        return;
      }

      // Check if student ID is already in use
      if (await _isStudentIdTaken(profileData.studentId)) {
        _showErrorSnackBar('student_id_already_exists'.tr());
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _isStudentIdTaken(String studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('student_id', isEqualTo: studentId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking student ID availability: $e');
      return false;
    }
  }

  Future<void> _updateUserProfile(String uid, ProfileData profileData) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final batch = FirebaseFirestore.instance.batch();

    batch.update(userDoc, profileData.toFirestoreMap());
    await batch.commit();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'dismiss'.tr(),
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Theme.of(context).canvasColor,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.7,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        inputDecoration: InputDecoration(
          labelText: 'search_country'.tr(),
          hintText: 'start_typing_country_name'.tr(),
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
        ),
      ),
      onSelect: (Country country) {
        if (mounted) {
          setState(() {
            _selectedCountry = country;
            _countryController.text = country.name;
          });
        }
      },
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('could_not_open_link'.tr());
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      _showErrorSnackBar('could_not_open_link'.tr());
    }
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
              const SizedBox(height: 24),
              _buildTermsAndPrivacyText(),
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
            validator: (value) => _validateName(value, 'first_name'.tr()),
            enabled: !_isSubmitting,
            maxLength: 50,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _lastNameController,
            decoration: buildInputDecoration('last_name'.tr()),
            textCapitalization: TextCapitalization.words,
            validator: (value) => _validateName(value, 'last_name'.tr()),
            enabled: !_isSubmitting,
            maxLength: 50,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: buildInputDecoration('username'.tr()).copyWith(
        helperText: 'username_requirements'.tr(),
        helperMaxLines: 2,
      ),
      validator: _validateUsername,
      onChanged: _onUsernameChanged,
      enabled: !_isSubmitting,
      maxLength: _maxUsernameLength,
      buildCounter: (context,
          {required currentLength, required isFocused, maxLength}) {
        return Text(
          '$currentLength/$maxLength',
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _usernameSuggestions.map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              onPressed: _isSubmitting
                  ? null
                  : () => _selectUsernameSuggestion(suggestion),
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
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
        prefixIcon: _selectedCountry != null
            ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  _selectedCountry!.flagEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              )
            : const Icon(Icons.public),
      ),
      readOnly: true,
      onTap: _isSubmitting ? null : _showCountryPicker,
      validator: (value) => _validateRequired(value, 'country'.tr()),
      enabled: !_isSubmitting,
    );
  }

  Widget _buildStudentIdField() {
    return TextFormField(
      controller: _studentIdController,
      decoration: buildInputDecoration('student_id'.tr()).copyWith(
        helperText: 'student_id_format_help'.tr(),
        prefixIcon: const Icon(Icons.school),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(_studentIdLength),
      ],
      validator: _validateStudentId,
      enabled: !_isSubmitting,
    );
  }

  Widget _buildPhoneField() {
    return IntlPhoneField(
      controller: _phoneController,
      decoration: buildInputDecoration('phone_number'.tr()),
      initialCountryCode: _selectedCountry?.countryCode ?? 'US',
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (phone) {
        _phoneNumberWithCountryCode = phone.completeNumber;
        if (mounted) {
          setState(() => _isPhoneValid = phone.isValidNumber());
        }
      },
      validator: (phone) {
        if (phone == null || phone.number.isEmpty) return 'phone_required'.tr();
        if (!phone.isValidNumber()) return 'phone_invalid_format'.tr();
        return null;
      },
      enabled: !_isSubmitting,
      dropdownIcon: const Icon(Icons.arrow_drop_down),
      flagsButtonPadding: const EdgeInsets.only(left: 8),
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
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('submitting'.tr()),
                ],
              )
            : Text('complete_profile'.tr()),
      ),
    );
  }

  Widget _buildTermsAndPrivacyText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text.rich(
        TextSpan(
          text: 'by_continuing_you_agree'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.8),
              ),
          children: [
            const TextSpan(text: " "),
            TextSpan(
              text: 'terms_of_service'.tr(),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl('https://yourapp.com/terms'),
            ),
            const TextSpan(text: " "),
            TextSpan(text: 'and'.tr()),
            const TextSpan(text: " "),
            TextSpan(
              text: 'privacy_policy'.tr(),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl('https://yourapp.com/privacy'),
            ),
            const TextSpan(text: "."),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
