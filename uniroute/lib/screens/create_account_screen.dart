// create_account_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';

import '../auth_services.dart';
import '../widgets/common_widgets.dart';
import '../utils/validators.dart';
import '../constants.dart';
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

  // Debounce timer for email validation
  Timer? _emailDebounceTimer;
  bool _isEmailChecking = false;
  String? _emailError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailDebounceTimer?.cancel();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _generalError = null;
    });
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
        _emailError = methods.isNotEmpty ? 'Email is already in use' : null;
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
    _clearErrors();

    if (!_formKey.currentState!.validate()) return;
    if (_emailError != null) {
      setState(() {
        _generalError = _emailError!;
      });
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
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(email)
          .set({
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
      setState(() {
        _generalError = 'An unknown error occurred';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    final message = switch (e.code) {
      'weak-password' => 'Password is too weak',
      'invalid-email' => 'Invalid email format',
      'operation-not-allowed' => 'Authentication not allowed',
      'email-already-in-use' => 'Email is already in use',
      'network-request-failed' => 'Network error occurred',
      _ => 'Authentication error occurred',
    };

    setState(() {
      _generalError = message;
    });
  }

  Future<void> _signInWithProvider(
    Future<UserCredential?> Function() signInMethod,
  ) async {
    if (_isLoading) return;

    _clearErrors();
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
        setState(() {
          _generalError = 'Provider sign-in failed';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildErrorContainer(String? error) {
    if (error == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withOpacity(0.1),
        border: Border.all(
          color: AppConstants.errorColor.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cornerRadius),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppConstants.errorColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppConstants.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        enabled: !_isLoading,
        onChanged: (value) {
          _onEmailChanged(value);
          _clearErrors();
        },
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
        decoration: buildInputDecoration('Email@domain.com').copyWith(
          prefixIcon: Icon(
            Icons.email_outlined,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          suffixIcon: _isEmailChecking
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _emailError == null &&
                      _emailController.text.isNotEmpty &&
                      AppValidators.email(_emailController.text) == null
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
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_showPassword,
        textInputAction: TextInputAction.next,
        enabled: !_isLoading,
        onChanged: (_) => _clearErrors(),
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
        decoration: buildInputDecoration('Password').copyWith(
          prefixIcon: Icon(
            Icons.lock_outline,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            onPressed: _isLoading
                ? null
                : () => setState(() => _showPassword = !_showPassword),
          ),
        ),
        validator: AppValidators.password,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: !_showConfirmPassword,
        textInputAction: TextInputAction.done,
        enabled: !_isLoading,
        onChanged: (_) => _clearErrors(),
        onFieldSubmitted: (_) => _createAccount(),
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
        decoration: buildInputDecoration('Re-type Password').copyWith(
          prefixIcon: Icon(
            Icons.lock_outline,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            onPressed: _isLoading
                ? null
                : () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword),
          ),
        ),
        validator: (value) =>
            AppValidators.confirmPassword(value, _passwordController.text),
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor:
              theme.colorScheme.onSurface.withOpacity(0.12),
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
                "Continue",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "or",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required Widget icon,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? borderColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: (borderColor ?? theme.colorScheme.outline).withOpacity(0.2),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textColor ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _buildSocialButton(
          text: "Continue with Google",
          icon: Image.asset('assets/images/google_logo.png',
              width: 24, height: 24),
          onPressed: () => _signInWithProvider(
            AuthServices.signInWithGoogle,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsText(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: Text.rich(
        TextSpan(
          text: "By clicking continue, you agree to our ",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: "Terms of Service",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Navigate to terms
                },
            ),
            const TextSpan(text: " and "),
            TextSpan(
              text: "Privacy Policy",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Navigate to privacy
                },
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoginLink() {
    final theme = Theme.of(context);

    return Center(
      child: TextButton(
        onPressed: _isLoading
            ? null
            : () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
                ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Already have an account? Sign in',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Create an account",
      subtitle: "Enter your email to sign up for this app",
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // General Error Display
              _buildErrorContainer(_generalError),

              _buildEmailField(),
              _buildPasswordField(),
              _buildConfirmPasswordField(),
              _buildCreateAccountButton(),
              _buildDivider(),
              _buildSocialButtons(),
              const SizedBox(height: 12),
              _buildTermsText(context),
              const SizedBox(height: 32),
              _buildLoginLink(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
