// complete_profile_screen.dart - FIXED VERSION
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/common_widgets.dart';
import 'home_screen.dart';

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
        'updated_at': FieldValue.serverTimestamp(), // Add this
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
  String? _generalError;

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

  void _clearErrors() {
    setState(() {
      _generalError = null;
    });
  }

  String? _validateStudentId(String? value) {
    final val = value?.trim() ?? '';
    if (val.isEmpty) return "Student ID is required";
    if (val.length != _studentIdLength) {
      return "Student ID must be 8 digits";
    }
    if (!val.startsWith(_studentIdPrefix)) {
      return "Student ID must start with 3";
    }
    if (!RegExp(r'^\d+$').hasMatch(val)) {
      return "Student ID must contain numbers only";
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$fieldName is required';
    if (trimmed.length < 2) return '$fieldName must be at least 2 characters';
    if (trimmed.length > 50) {
      return '$fieldName must be less than 50 characters';
    }
    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(trimmed)) {
      return '$fieldName contains invalid characters';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return "Username is required";
    if (trimmed.length < _minUsernameLength) {
      return "Username must be at least 3 characters";
    }
    if (trimmed.length > _maxUsernameLength) {
      return "Username must be less than 20 characters";
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(trimmed)) {
      return "Username can only contain letters, numbers, dots, underscores, and hyphens";
    }
    if (RegExp(r'[._-]{2,}').hasMatch(trimmed)) {
      return "Username cannot have consecutive special characters";
    }
    if (RegExp(r'^[._-]|[._-]$').hasMatch(trimmed)) {
      return "Username cannot start or end with special characters";
    }
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
    _clearErrors();
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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No current user found');
        _showErrorSnackBar('User not logged in');
        return null;
      }

      // Reload user to get fresh data
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        debugPrint('User became null after reload');
        _showErrorSnackBar('Authentication error');
        return null;
      }

      // Check if email is verified
      if (!refreshedUser.emailVerified) {
        debugPrint('User email not verified: ${refreshedUser.email}');
        _showErrorSnackBar(
            'Please verify your email before completing profile');
        return null;
      }

      debugPrint('User validated successfully: ${refreshedUser.email}');
      return refreshedUser;
    } catch (e) {
      debugPrint('Error validating current user: $e');
      _showErrorSnackBar('Authentication error: ${e.toString()}');
      return null;
    }
  }

  Future<void> _submitProfile() async {
    debugPrint('=== Starting profile submission ===');
    _clearErrors();

    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    if (!_isPhoneValid) {
      debugPrint('Phone number validation failed');
      _showErrorSnackBar('Phone number format is invalid');
      return;
    }

    final user = await _validateCurrentUser();
    if (user?.email == null) {
      debugPrint('User validation failed');
      return;
    }

    final profileData = _getProfileData();
    debugPrint('Profile data prepared: ${profileData.toFirestoreMap()}');

    setState(() => _isSubmitting = true);

    try {
      // Final username availability check
      debugPrint('Checking username availability: ${profileData.username}');
      if (!await _isUsernameAvailable(profileData.username)) {
        debugPrint('Username taken: ${profileData.username}');
        _showErrorSnackBar(
            'Username is taken. Please try one of the suggestions.');
        return;
      }

      // Check if student ID is already in use
      debugPrint('Checking student ID availability: ${profileData.studentId}');
      if (await _isStudentIdTaken(profileData.studentId)) {
        debugPrint('Student ID taken: ${profileData.studentId}');
        _showErrorSnackBar('Student ID already exists');
        return;
      }

      debugPrint('Starting Firestore update for user: ${user!.email}');
      await _updateUserProfile(user.email!, profileData);

      debugPrint('Profile update successful');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error during profile submission: $e');
      debugPrint('Error type: ${e.runtimeType}');

      String errorMessage = 'Failed to update profile';
      if (e is FirebaseException) {
        errorMessage = 'Database error: ${e.message}';
        debugPrint('Firebase error code: ${e.code}');
      } else if (e is PlatformException) {
        errorMessage = 'Platform error: ${e.message}';
      }

      _showErrorSnackBar(errorMessage);
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

      final isTaken = snapshot.docs.isNotEmpty;
      debugPrint('Student ID $studentId taken: $isTaken');
      return isTaken;
    } catch (e) {
      debugPrint('Error checking student ID availability: $e');
      return false;
    }
  }

  Future<void> _updateUserProfile(String email, ProfileData profileData) async {
    debugPrint('Updating profile for email: $email');

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(email);
      final profileMap = profileData.toFirestoreMap();

      debugPrint('Profile data to save: $profileMap');

      // Check if document exists first
      final docSnapshot = await userDoc.get();
      debugPrint('Document exists: ${docSnapshot.exists}');

      if (docSnapshot.exists) {
        // Update existing document
        debugPrint('Updating existing document');
        await userDoc.update(profileMap);
      } else {
        // Create new document
        debugPrint('Creating new document');
        profileMap['created_at'] = FieldValue.serverTimestamp();
        profileMap['email'] = email; // Add email field
        await userDoc.set(profileMap);
      }

      debugPrint('Firestore operation completed successfully');
    } catch (e) {
      debugPrint('Firestore operation failed: $e');
      if (e is FirebaseException) {
        debugPrint(
            'Firebase error details: code=${e.code}, message=${e.message}');
      }
      rethrow;
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    debugPrint('Showing error: $message');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false, // This is the key change - set to false
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Theme.of(context).canvasColor,
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.7,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search Country',
          hintText: 'Start typing country name',
          labelStyle: GoogleFonts.poppins(),
          hintStyle: GoogleFonts.poppins(),
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
        _showErrorSnackBar('Could not open link');
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      _showErrorSnackBar('Could not open link');
    }
  }

  Widget _buildErrorContainer(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Tell us about yourself",
      subtitle: "Complete your profile to get started",
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildErrorContainer(_generalError),
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
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextFormField(
              controller: _firstNameController,
              decoration: buildInputDecoration('First Name').copyWith(
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _validateName(value, 'First Name'),
              enabled: !_isSubmitting,
              onChanged: (_) => _clearErrors(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
              maxLength: 50,
              autofillHints: const [AutofillHints.givenName],
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            child: TextFormField(
              controller: _lastNameController,
              decoration: buildInputDecoration('Last Name').copyWith(
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _validateName(value, 'Last Name'),
              enabled: !_isSubmitting,
              onChanged: (_) => _clearErrors(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
              maxLength: 50,
              autofillHints: const [AutofillHints.familyName],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: _usernameController,
        decoration: buildInputDecoration('Username').copyWith(
          helperText:
              'Username can contain letters, numbers, dots, underscores, and hyphens',
          helperMaxLines: 2,
          helperStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            Icons.alternate_email,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        validator: _validateUsername,
        onChanged: _onUsernameChanged,
        enabled: !_isSubmitting,
        maxLength: _maxUsernameLength,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
        autofillHints: const [AutofillHints.username],
        buildCounter: (context,
            {required currentLength,
            required isFocused,
            required int? maxLength}) {
          return Text(
            '$currentLength/${maxLength ?? _maxUsernameLength}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsernameSuggestions() {
    if (_usernameSuggestions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Username Suggestions',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _usernameSuggestions.map((suggestion) {
              return ActionChip(
                label: Text(
                  suggestion,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () => _selectUsernameSuggestion(suggestion),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryField() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _countryController,
        decoration: buildInputDecoration('Country').copyWith(
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          prefixIcon: _selectedCountry != null
              ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _selectedCountry!.flagEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                )
              : Icon(
                  Icons.public,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
        ),
        readOnly: true,
        onTap: _isSubmitting ? null : _showCountryPicker,
        validator: (value) => _validateRequired(value, 'Country'),
        enabled: !_isSubmitting,
        onChanged: (_) => _clearErrors(),
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
        autofillHints: const [AutofillHints.countryName],
      ),
    );
  }

  Widget _buildStudentIdField() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _studentIdController,
        decoration: buildInputDecoration('Student ID').copyWith(
          helperText: 'Enter your 8-digit student ID starting with 3',
          helperStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            Icons.school,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(_studentIdLength),
        ],
        validator: _validateStudentId,
        enabled: !_isSubmitting,
        onChanged: (_) => _clearErrors(),
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
        autofillHints: const [AutofillHints.username],
      ),
    );
  }

  Widget _buildPhoneField() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: IntlPhoneField(
        controller: _phoneController,
        decoration: buildInputDecoration('Phone Number').copyWith(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        initialCountryCode: _selectedCountry?.countryCode ?? 'US',
        dropdownIconPosition: IconPosition.trailing,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(15),
        ],
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
        onChanged: (phone) {
          _clearErrors();
          _phoneNumberWithCountryCode = phone.completeNumber;
          if (mounted) {
            setState(() => _isPhoneValid = phone.isValidNumber());
          }
        },
        validator: (phone) {
          if (phone == null || phone.number.isEmpty) {
            return 'Phone number is required';
          }
          if (!phone.isValidNumber()) return 'Phone number format is invalid';
          return null;
        },
        enabled: !_isSubmitting,
        dropdownIcon: Icon(
          Icons.arrow_drop_down,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        flagsButtonPadding: const EdgeInsets.only(left: 8),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Complete Profile',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsAndPrivacyText() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text.rich(
        TextSpan(
          text: 'By continuing, you agree to our',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            height: 1.4,
          ),
          children: [
            const TextSpan(text: " "),
            TextSpan(
              text: 'Terms of Service',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl('https://yourapp.com/terms'),
            ),
            const TextSpan(text: " "),
            const TextSpan(text: 'and'),
            const TextSpan(text: " "),
            TextSpan(
              text: 'Privacy Policy',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w600,
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
