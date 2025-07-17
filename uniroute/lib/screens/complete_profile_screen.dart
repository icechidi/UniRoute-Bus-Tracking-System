// Flutter & Firebase imports
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

import 'email_verification_screen.dart';

/// Screen shown after initial account creation, to complete the user's profile.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with SingleTickerProviderStateMixin {
  // Text controllers for form fields
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // State variables
  bool _isSubmitting = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  List<String> _usernameSuggestions = [];
  PhoneNumber? _phoneNumber;

  // Animations for success feedback
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Constants for username validation
  static const _minUsernameLength = 3;
  static const _maxUsernameLength = 15;
  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');

  @override
  void initState() {
    super.initState();

    // Start checking for username uniqueness when user types
    usernameController.addListener(_debounceUsernameCheck);

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  Timer? _timer;

  /// Debounce logic to limit frequency of username availability checks
  void _debounceUsernameCheck() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), _checkUsernameUnique);
  }

  /// Checks whether the entered username is available
  Future<void> _checkUsernameUnique() async {
    final username = usernameController.text.trim();

    // Clear errors and suggestions if username is empty
    if (username.isEmpty) {
      setState(() {
        _usernameError = null;
        _usernameSuggestions = [];
      });
      return;
    }

    // Check for length constraints
    if (username.length < _minUsernameLength) {
      setState(() {
        _usernameError = "username_too_short".tr();
        _usernameSuggestions = [];
      });
      return;
    }

    if (username.length > _maxUsernameLength) {
      setState(() {
        _usernameError = "username_too_long".tr();
        _usernameSuggestions = [];
      });
      return;
    }

    // Check for valid characters
    if (!_usernameRegex.hasMatch(username)) {
      setState(() {
        _usernameError = "username_invalid_chars".tr();
        _usernameSuggestions = [];
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      // Query Firestore to check if username is already taken
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // If taken, generate 3 alternative suggestions
        _usernameSuggestions = _generateValidSuggestions(username);
        setState(() {
          _usernameError = "username_taken_suggestions"
              .tr(args: [_usernameSuggestions.join(", ")]);
        });
      } else {
        setState(() {
          _usernameError = null;
          _usernameSuggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        _usernameError = "username_check_failed".tr();
      });
    } finally {
      setState(() => _isCheckingUsername = false);
    }
  }

  /// Generate valid alternative usernames by appending random 4-digit numbers
  List<String> _generateValidSuggestions(String base) {
    final random = Random();
    final suggestions = <String>[];
    var attempts = 0;

    while (suggestions.length < 3 && attempts < 10) {
      final suggestion = "$base${random.nextInt(9000) + 1000}";
      if (suggestion.length <= _maxUsernameLength &&
          _usernameRegex.hasMatch(suggestion)) {
        suggestions.add(suggestion);
      }
      attempts++;
    }

    return suggestions;
  }

  @override
  void dispose() {
    usernameController.removeListener(_debounceUsernameCheck);
    _timer?.cancel();
    fullNameController.dispose();
    usernameController.dispose();
    countryController.dispose();
    phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              // App logo
                              Image.asset(
                                'assets/images/bus_logo.png',
                                height: 100,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "complete_profile".tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Full Name Input
                        TextField(
                          controller: fullNameController,
                          decoration: _inputDecoration("full_name".tr()),
                          textCapitalization: TextCapitalization.words,
                        ),

                        const SizedBox(height: 16),

                        // Username Input with validation and suggestions
                        TextField(
                          controller: usernameController,
                          maxLength: _maxUsernameLength,
                          decoration:
                              _inputDecoration("username".tr()).copyWith(
                            errorText: _usernameError,
                            counterText: '',
                            suffixIcon: _isCheckingUsername
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),

                        // Suggestion Chips for username
                        if (_usernameSuggestions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              children: _usernameSuggestions
                                  .map((s) => ActionChip(
                                        label: Text(s),
                                        onPressed: () {
                                          usernameController.text = s;
                                          setState(() {
                                            _usernameError = null;
                                            _usernameSuggestions = [];
                                          });
                                        },
                                      ))
                                  .toList(),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Country Picker
                        GestureDetector(
                          onTap: () {
                            showCountryPicker(
                              context: context,
                              showPhoneCode: false,
                              onSelect: (Country country) {
                                setState(() {
                                  countryController.text = country.name;
                                });
                              },
                            );
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: countryController,
                              readOnly: true,
                              decoration:
                                  _inputDecoration("choose_country".tr())
                                      .copyWith(
                                suffixIcon: const Icon(Icons.arrow_drop_down),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Phone Number Input with validation
                        IntlPhoneField(
                          controller: phoneController,
                          decoration: _inputDecoration("phone".tr()),
                          initialCountryCode: 'TR',
                          onChanged: (phone) {
                            _phoneNumber = phone;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ], // ✅ Restrict input to digits only
                          validator: (phone) {
                            if (phone?.number.isEmpty ?? true) {
                              return "phone_required".tr();
                            }
                            if (phone!.number.length < 8) {
                              return "phone_too_short".tr();
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text("continue".tr(),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Terms and Privacy links
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: "terms_agree".tr(),
                              style: const TextStyle(color: Colors.grey),
                              children: [
                                TextSpan(
                                  text: "terms_of_service".tr(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushNamed(
                                          context, '/termsOfService');
                                    },
                                ),
                                const TextSpan(text: " and "),
                                TextSpan(
                                  text: "privacy_policy".tr(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushNamed(
                                          context, '/privacyPolicy');
                                    },
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// Input styling used throughout the form
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  /// Called when the user taps "Continue" to submit the profile
  Future<void> _submitProfile() async {
    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    final country = countryController.text.trim();
    final email = FirebaseAuth.instance.currentUser?.email;

    // Ensure all required fields are filled
    if (fullName.isEmpty ||
        username.isEmpty ||
        country.isEmpty ||
        _phoneNumber == null ||
        _phoneNumber!.number.isEmpty ||
        email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_complete_all_fields'.tr())),
      );
      return;
    }

    // Revalidate username before submission
    if (_usernameError != null || !_usernameRegex.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('invalid_username'.tr())),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Double-check if username was taken in the meantime
      final usernameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (usernameSnapshot.docs.isNotEmpty) {
        final suggestion = _generateValidSuggestions(username).first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("username_taken_suggestion".tr(args: [suggestion])),
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final formattedPhone =
          '+${_phoneNumber!.countryCode}${_phoneNumber!.number}';

      // Save the completed profile to Firestore
      await FirebaseFirestore.instance.collection('users').doc(email).update({
        'full_name': fullName,
        'username': username.toLowerCase(),
        'country': country,
        'phone': formattedPhone,
        'phone_country_code': _phoneNumber!.countryCode,
        'status': 'unverified',
        'profile_completed_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Play animation and show success snackbar
      _animationController.forward();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          content: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text("profile_saved".tr())),
                ],
              ),
            ),
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigate to email verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email)),
      );
    } on FirebaseException catch (e) {
      // Handle known Firebase errors
      String errorMessage = "failed_to_update_profile".tr();
      if (e.code == 'permission-denied') {
        errorMessage = "permission_denied".tr();
      } else if (e.code == 'aborted') {
        errorMessage = "operation_aborted".tr();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      // Fallback for unknown errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("unexpected_error".tr())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
