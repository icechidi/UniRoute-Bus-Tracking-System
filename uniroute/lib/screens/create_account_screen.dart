// create_account_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'dart:async';

import '../auth_services.dart';
import '../widgets/common_widgets.dart';
import '../utils/validators.dart';
import 'email_verification_screen.dart';
import 'student_login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptTerms = false;

  // Debounce timer for email validation
  Timer? _emailDebounceTimer;
  bool _isEmailChecking = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailDebounceTimer?.cancel();
    super.dispose();
  }

  void _onEmailChanged(String email) {
    _emailDebounceTimer?.cancel();
    setState(() {
      _emailError = null;
      _isEmailChecking = false;
    });

    if (email.trim().isEmpty || AppValidators.email(email) != null) {
      return;
    }

    _emailDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _checkEmailAvailability(email.trim());
    });
  }

  Future<void> _checkEmailAvailability(String email) async {
    if (!mounted) return;

    setState(() => _isEmailChecking = true);

    try {
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (!mounted) return;

      setState(() {
        _isEmailChecking = false;
        _emailError = methods.isNotEmpty ? 'email_already_in_use'.tr() : null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEmailChecking = false;
          _emailError = null;
        });
      }
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showSnackBar('accept_terms_to_continue'.tr(), Colors.orange);
      return;
    }
    if (_emailError != null) {
      _showSnackBar(_emailError!, Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Create user account
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) throw Exception("User creation failed");

      // Create user document
      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'email': email,
        'uid': user.uid,
        'email_status': 'unverified',
        'account_status': 'incomplete',
        'created_at': FieldValue.serverTimestamp(),
      });

      // Send verification email
      await user.sendEmailVerification();

      if (!mounted) return;

      // Navigate to email verification
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: email),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
    } catch (e) {
      _showSnackBar('unknown_error_occurred'.tr(), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    final message = switch (e.code) {
      'weak-password' => 'password_too_weak'.tr(),
      'invalid-email' => 'invalid_email_format'.tr(),
      'operation-not-allowed' => 'auth_not_allowed'.tr(),
      'email-already-in-use' => 'email_already_in_use'.tr(),
      'network-request-failed' => 'network_error'.tr(),
      _ => 'auth_error_occurred'.tr(),
    };

    _showSnackBar(message, Colors.red);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _signInWithProvider(
    Future<UserCredential?> Function() signInMethod,
  ) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await signInMethod();
      if (userCredential?.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: userCredential?.user?.email ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('provider_signin_failed'.tr(), Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildEmailField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        onChanged: _onEmailChanged,
        decoration: buildInputDecoration('email_hint').copyWith(
          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
          suffixIcon: _isEmailChecking
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _emailError == null && _emailController.text.isNotEmpty
                  ? Icon(Icons.check_circle, color: Colors.green[600])
                  : null,
          errorText: _emailError,
        ),
        validator: AppValidators.email,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_showPassword,
        decoration: buildInputDecoration('password_hint').copyWith(
          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
        validator: AppValidators.password,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: !_showConfirmPassword,
        decoration: buildInputDecoration('confirm_password_hint').copyWith(
          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
          suffixIcon: IconButton(
            icon: Icon(
              _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: () =>
                setState(() => _showConfirmPassword = !_showConfirmPassword),
          ),
        ),
        validator: (value) =>
            AppValidators.confirmPassword(value, _passwordController.text),
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _acceptTerms,
            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(child: _buildTermsAndPrivacyText()),
        ],
      ),
    );
  }

  Widget _buildTermsAndPrivacyText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text.rich(
        TextSpan(
          text: 'i_agree_to'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.4,
          ),
          children: [
            const TextSpan(text: " "),
            TextSpan(
              text: 'terms_of_service'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Open terms
                },
            ),
            TextSpan(
              text: " ${'and'.tr()} ",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            TextSpan(
              text: 'privacy_policy'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Open privacy
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Text(
                "continue".tr(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "or".tr(),
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _buildSocialButton(
          text: "continue_google",
          icon: Image.asset('assets/images/google_logo.png',
              width: 24, height: 24),
          onPressed: () => _signInWithProvider(
            AuthServices.signInWithGoogle,
          ),
        ),
        if (!kIsWeb) ...[
          const SizedBox(height: 12),
          _buildSocialButton(
            text: "continue_apple",
            icon: const Icon(Icons.apple, color: Colors.white, size: 24),
            backgroundColor: Colors.black,
            borderColor: Colors.black,
            textColor: Colors.white,
            onPressed: () => _signInWithProvider(
              AuthServices.signInWithApple,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialButton({
    required String text,
    required Widget icon,
    Color backgroundColor = Colors.white,
    Color borderColor = Colors.grey,
    Color textColor = Colors.black,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: borderColor.withOpacity(0.3), width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
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

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: _isLoading
            ? null
            : () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
                ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          'already_have_account'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "create_account".tr(),
      subtitle: "enter_email_to_signup".tr(),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEmailField(),
              _buildPasswordField(),
              _buildConfirmPasswordField(),
              _buildTermsCheckbox(),
              _buildCreateAccountButton(),
              _buildDivider(),
              _buildSocialButtons(),
              const SizedBox(height: 32),
              _buildLoginLink(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
