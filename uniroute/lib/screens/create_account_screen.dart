import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../auth_services.dart';
import '../widgets/common_widgets.dart';
import 'complete_profile_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  DateTime? _lastAttemptTime;
  int _attemptCount = 0;

  // Error states
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _emailError == null && 
           _passwordError == null && 
           _confirmPasswordError == null &&
           _emailController.text.isNotEmpty &&
           _passwordController.text.isNotEmpty &&
           _confirmPasswordController.text.isNotEmpty;
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = null);
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() => _emailError = "invalid_email".tr());
    } else {
      setState(() => _emailError = null);
    }
  }

  void _validatePassword() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _passwordError = null);
      return;
    }

    if (!_isPasswordStrong(password)) {
      setState(() => _passwordError = "weak_password".tr());
    } else {
      setState(() => _passwordError = null);
    }

    // Also validate confirm password when password changes
    _validateConfirmPassword();
  }

  void _validateConfirmPassword() {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = null);
      return;
    }

    if (password != confirmPassword) {
      setState(() => _confirmPasswordError = "passwords_do_not_match".tr());
    } else {
      setState(() => _confirmPasswordError = null);
    }
  }

  Future<void> _createAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Rate limiting
    final now = DateTime.now();
    if (_lastAttemptTime != null && 
        now.difference(_lastAttemptTime!) < const Duration(minutes: 1)) {
      _attemptCount++;
      if (_attemptCount >= 5) {
        _showDialog("too_many_attempts".tr());
        return;
      }
    } else {
      _attemptCount = 1;
    }
    _lastAttemptTime = now;

    setState(() => _isLoading = true);

    try {
      // Check if email exists
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        setState(() => _emailError = "email_already_used".tr());
        return;
      }

      // Create user
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.email)
          .set({
        'email': email,
        'status': 'unverified',
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user?.uid,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
      );
    } on FirebaseAuthException catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      _showDialog(_getErrorMessage(e));
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      _showDialog("unexpected_error".tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isPasswordStrong(String password) {
    // At least 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()\-_=+{};:,<.>]).{8,}$')
        .hasMatch(password);
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "email_already_used".tr();
      case 'weak-password':
        return "weak_password".tr();
      case 'invalid-email':
        return "invalid_email".tr();
      case 'operation-not-allowed':
        return "operation_not_allowed".tr();
      default:
        return "signup_failed".tr();
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("error".tr(), style: GoogleFonts.poppins()),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text("ok".tr(), style: GoogleFonts.poppins()),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    if (password.isEmpty) return const SizedBox.shrink();
    
    final strength = _calculatePasswordStrength(password);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: strength.value,
          backgroundColor: Colors.grey[200],
          color: strength.color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Text(
          strength.text.tr(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: strength.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  _PasswordStrength _calculatePasswordStrength(String password) {
    if (password.length < 8) return _PasswordStrength.weak();
    
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    final strength = (hasUpper ? 1 : 0) + 
                    (hasLower ? 1 : 0) + 
                    (hasDigit ? 1 : 0) + 
                    (hasSpecial ? 1 : 0);

    if (strength <= 2) return _PasswordStrength.weak();
    if (strength == 3) return _PasswordStrength.medium();
    return _PasswordStrength.strong();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "create_account".tr(),
      subtitle: "enter_email_to_signup".tr(),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: buildInputDecoration('email_hint').copyWith(
              errorText: _emailError,
              errorStyle: GoogleFonts.poppins(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _emailError != null ? Colors.red : Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _emailError != null ? Colors.red : Colors.black,
                  width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => _validateEmail(),
          ),
          if (_emailError != null) 
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _emailError!,
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: buildInputDecoration('password_hint').copyWith(
              errorText: _passwordError,
              errorStyle: GoogleFonts.poppins(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _passwordError != null ? Colors.red : Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _passwordError != null ? Colors.red : Colors.black,
                  width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            onChanged: (_) => _validatePassword(),
          ),
          const SizedBox(height: 4),
          _buildPasswordStrengthIndicator(_passwordController.text),
          if (_passwordError != null) 
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _passwordError!,
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            decoration: buildInputDecoration('confirm_password_hint').copyWith(
              errorText: _confirmPasswordError,
              errorStyle: GoogleFonts.poppins(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _confirmPasswordError != null ? Colors.red : Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _confirmPasswordError != null ? Colors.red : Colors.black,
                  width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              ),
            ),
            onChanged: (_) => _validateConfirmPassword(),
          ),
          if (_confirmPasswordError != null) 
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _confirmPasswordError!,
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isFormValid && !_isLoading ? _createAccount : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
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
          Row(
            children: [
              const Expanded(child: Divider(thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "or".tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const Expanded(child: Divider(thickness: 1)),
            ],
          ),
          const SizedBox(height: 20),
          // Google Sign-In Button
          _buildSocialButton(
            text: "continue_google",
            icon: Image.asset(
              'assets/images/google_logo.png',
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              final userCredential = await AuthServices.signInWithGoogle();
              if (userCredential?.user != null && mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
                );
              }
            },
          ),
          // Apple Sign-In Button (iOS only)
          if (!kIsWeb)
            _buildSocialButton(
              text: "continue_apple",
              icon: const Icon(
                Icons.apple,
                color: Colors.white,
                size: 24,
              ),
              backgroundColor: Colors.black,
              borderColor: Colors.black,
              textColor: Colors.white,
              onPressed: () async {
                final userCredential = await AuthServices.signInWithApple();
                if (userCredential?.user != null && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
                  );
                }
              },
            ),
          const SizedBox(height: 20),
          buildTermsText(context),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required Widget icon,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.white,
    Color borderColor = Colors.grey,
    Color textColor = Colors.black87,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              text.tr(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrength {
  final double value;
  final Color color;
  final String text;

  _PasswordStrength(this.value, this.color, this.text);

  factory _PasswordStrength.weak() => 
    _PasswordStrength(0.33, Colors.red, "weak_password_strength");

  factory _PasswordStrength.medium() => 
    _PasswordStrength(0.66, Colors.orange, "medium_password_strength");

  factory _PasswordStrength.strong() => 
    _PasswordStrength(1.0, Colors.green, "strong_password_strength");
}