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

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with SingleTickerProviderStateMixin {
  // Text controllers
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

  // Username validation constants
  static const int _minUsernameLength = 3;
  static const int _maxUsernameLength = 15;
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    usernameController.addListener(_onUsernameChanged);

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

  void _onUsernameChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _checkUsernameUnique);
  }

  Future<void> _checkUsernameUnique() async {
    final username = usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _usernameError = null;
        _usernameSuggestions = [];
      });
      return;
    }

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

    if (!_usernameRegex.hasMatch(username)) {
      setState(() {
        _usernameError = "username_invalid_chars".tr();
        _usernameSuggestions = [];
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final suggestions = _generateUsernameSuggestions(username);
        setState(() {
          _usernameError = "username_taken_suggestions".tr(args: [suggestions.join(", ")]);
          _usernameSuggestions = suggestions;
        });
      } else {
        setState(() {
          _usernameError = null;
          _usernameSuggestions = [];
        });
      }
    } catch (_) {
      setState(() {
        _usernameError = "username_check_failed".tr();
      });
    } finally {
      setState(() => _isCheckingUsername = false);
    }
  }

  List<String> _generateUsernameSuggestions(String base) {
    final random = Random();
    final suggestions = <String>{};

    while (suggestions.length < 3) {
      final suffix = random.nextInt(9000) + 1000; // 4-digit number
      final suggestion = "$base$suffix";
      if (suggestion.length <= _maxUsernameLength &&
          _usernameRegex.hasMatch(suggestion)) {
        suggestions.add(suggestion);
      }
    }

    return suggestions.toList();
  }

  @override
  void dispose() {
    usernameController.removeListener(_onUsernameChanged);
    _debounceTimer?.cancel();
    fullNameController.dispose();
    usernameController.dispose();
    countryController.dispose();
    phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

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

  Future<void> _submitProfile() async {
    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    final country = countryController.text.trim();
    final email = FirebaseAuth.instance.currentUser?.email;

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

    if (_usernameError != null || !_usernameRegex.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('invalid_username'.tr())),
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
        final suggestion = _generateUsernameSuggestions(username).first;
        if (!mounted) return;
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: email),
        ),
      );
    } on FirebaseException catch (e) {
      String errorMessage = "failed_to_update_profile".tr();
      if (e.code == 'permission-denied') {
        errorMessage = "permission_denied".tr();
      } else if (e.code == 'aborted') {
        errorMessage = "operation_aborted".tr();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("unexpected_error".tr())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/bus_logo.png',
                                height: 100,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "complete_profile".tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        TextField(
                          controller: fullNameController,
                          decoration: _inputDecoration("full_name".tr()),
                          textCapitalization: TextCapitalization.words,
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: usernameController,
                          maxLength: _maxUsernameLength,
                          decoration: _inputDecoration("username".tr()).copyWith(
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

                        if (_usernameSuggestions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              children: _usernameSuggestions
                                  .map((suggestion) => ActionChip(
                                        label: Text(suggestion),
                                        onPressed: () {
                                          usernameController.text = suggestion;
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

                        GestureDetector(
                          onTap: () {
                            showCountryPicker(
                              context: context,
                              showPhoneCode: false,
                              onSelect: (country) {
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
                              decoration: _inputDecoration("choose_country".tr())
                                  .copyWith(
                                suffixIcon:
                                    const Icon(Icons.arrow_drop_down_rounded),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        IntlPhoneField(
                          controller: phoneController,
                          decoration: _inputDecoration("phone".tr()),
                          initialCountryCode: 'TR',
                          onChanged: (phone) {
                            _phoneNumber = phone;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (phone) {
                            if (phone == null || phone.number.isEmpty) {
                              return "phone_required".tr();
                            }
                            if (phone.number.length < 8) {
                              return "phone_too_short".tr();
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

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
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "continue".tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

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
                                    color: Colors.black,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () =>
                                        Navigator.pushNamed(context, '/termsOfService'),
                                ),
                                const TextSpan(text: " and "),
                                TextSpan(
                                  text: "privacy_policy".tr(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () =>
                                        Navigator.pushNamed(context, '/privacyPolicy'),
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
}
