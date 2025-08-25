// lib/screens/student_login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

import '../auth_services.dart';
import '../widgets/common_widgets.dart';
import '../utils/validators.dart';
import '../constants.dart';

import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'complete_profile_screen.dart';
import 'email_verification_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  bool _keepSignedIn = false;

  String? _generalError;

  @override
  void initState() {
    super.initState();
    AuthServices.shouldKeepSignedIn().then((v) {
      if (mounted) setState(() => _keepSignedIn = v);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _generalError = null;
    });
  }

  Future<void> _loginWithEmail() async {
    _clearErrors();

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      // Use AuthServices sign-in which returns a user map (or throws on error)
      final user =
          await AuthServices.signInWithEmail(email, password, _keepSignedIn);

      if (user != null) {
        // NOTE: Previously you used Firestore to check account status.
        // If your backend returns account status inside the user payload, check it here.
        // Example:
        // final accountStatus = user['account_status'] ?? 'complete';
        // if (accountStatus == 'incomplete') navigate to CompleteProfileScreen(), etc.
        //
        // For now, assume login successful and navigate to HomeScreen:
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() {
          _generalError = 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('Login error: $e');
      setState(() {
        _generalError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToEmailVerification(String email) async {
    if (!mounted) return;
    await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email)));
  }

  Future<void> _navigateToCompleteProfile() async {
    if (!mounted) return;
    await Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()));
  }

  Future<void> _navigateToSuccess() async {
    if (!mounted) return;
    await Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _navigateToCreateAccount() {
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const CreateAccountScreen()));
  }

  void _navigateToForgotPassword() {
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
  }

  void _showAccountNotFoundDialog() {
    if (!mounted) return;

    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cornerRadius)),
          title: Text("Account Not Found",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface)),
          content: Text(
              "No account exists with this email address. Would you like to create a new account?",
              style: GoogleFonts.poppins(color: theme.colorScheme.onSurface)),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text("Cancel",
                    style: GoogleFonts.poppins(
                        color: theme.colorScheme.onSurface.withOpacity(0.6)))),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) _navigateToCreateAccount();
              },
              child: Text("Create Account",
                  style: GoogleFonts.poppins(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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
              color: AppConstants.errorColor.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(AppConstants.cornerRadius)),
      child: Row(children: [
        const Icon(Icons.error_outline,
            color: AppConstants.errorColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: Text(error,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppConstants.errorColor,
                    fontWeight: FontWeight.w500))),
      ]),
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
              color:
                  (borderColor ?? theme.colorScheme.outline).withOpacity(0.2),
              width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon,
          const SizedBox(width: 12),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: textColor ?? theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildTermsText(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text.rich(
        TextSpan(
            text: "By clicking continue, you agree to our ",
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.4),
            children: [
              TextSpan(
                  text: "Terms of Service",
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()..onTap = () {}),
              const TextSpan(text: " and "),
              TextSpan(
                  text: "Privacy Policy",
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()..onTap = () {}),
            ]),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isAppleSignInAvailable =
        defaultTargetPlatform == TargetPlatform.iOS; // simple check

    return AuthScaffold(
      title: "Login",
      subtitle: "Enter your email to sign in for this app",
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildErrorContainer(_generalError),
            // Email Field
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                validator: AppValidators.email,
                onChanged: (_) => _clearErrors(),
                style: GoogleFonts.poppins(
                    fontSize: 16, color: theme.colorScheme.onSurface),
                decoration:
                    buildInputDecoration('Email, Username or Student ID')
                        .copyWith(
                            prefixIcon: Icon(Icons.email_outlined,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6))),
              ),
            ),
            // Password Field
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                textInputAction: TextInputAction.done,
                enabled: !_isLoading,
                validator: AppValidators.password,
                onFieldSubmitted: (_) => _loginWithEmail(),
                onChanged: (_) => _clearErrors(),
                style: GoogleFonts.poppins(
                    fontSize: 16, color: theme.colorScheme.onSurface),
                decoration: buildInputDecoration('Password').copyWith(
                    prefixIcon: Icon(Icons.lock_outline,
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    suffixIcon: IconButton(
                        icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6)),
                        onPressed: _isLoading
                            ? null
                            : () => setState(
                                () => _showPassword = !_showPassword))),
              ),
            ),
            // Keep signed in checkbox
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Row(children: [
                Checkbox(
                    value: _keepSignedIn,
                    onChanged: _isLoading
                        ? null
                        : (v) => setState(() => _keepSignedIn = v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    activeColor: Colors.black),
                Expanded(
                    child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () =>
                                setState(() => _keepSignedIn = !_keepSignedIn),
                        child: Text("Keep me signed in",
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7))))),
              ]),
            ),
            // Login Button
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginWithEmail,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    disabledBackgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.12)),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                            strokeWidth: 2))
                    : Text("Continue",
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            // OR Divider
            Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Row(children: [
                  Expanded(
                      child: Divider(
                          color: theme.colorScheme.outline.withOpacity(0.3))),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("or",
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.6)))),
                  Expanded(
                      child: Divider(
                          color: theme.colorScheme.outline.withOpacity(0.3)))
                ])),
            // Social Login Buttons
            _buildTermsText(context),
            const SizedBox(height: 32),
            // Bottom Buttons
            Row(children: [
              Expanded(
                  child: TextButton(
                      onPressed: _isLoading ? null : _navigateToForgotPassword,
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: Text("Forgot Password?",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500)))),
              Expanded(
                  child: TextButton(
                      onPressed: _isLoading ? null : _navigateToCreateAccount,
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: Text("Create an Account",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)))),
            ]),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }
}
