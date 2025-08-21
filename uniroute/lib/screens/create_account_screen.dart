// lib/screens/create_account_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

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

  // Backend endpoint to create account - update if needed
  static const String createUserUrl = 'http://10.0.2.2:3000/api/users';

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
      // Quick availability check by calling your login or users endpoint would risk exposing
      // info. Here we call the users endpoint to see if that email already exists.
      // If your GET /api/users does not support query by email, remove this check.
      final uri = Uri.parse('http://10.0.2.2:3000/api/users?email=$email');
      final resp = await http.get(uri);
      if (!mounted) return;

      // If endpoint returns array of users and includes email, mark as taken.
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        final exists = (body is List && body.any((u) => u['email'] == email));
        setState(() {
          _isEmailChecking = false;
          _emailError = exists ? 'Email is already in use' : null;
        });
      } else {
        // If the endpoint doesn't support this check, ignore
        setState(() {
          _isEmailChecking = false;
          _emailError = null;
        });
      }
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

      // Send create request to your backend
      final resp = await http.post(
        Uri.parse(createUserUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          // minimal fields - expand if your backend requires them
          'email': email,
          'password': password,
          // add role_id if required, e.g. 'role_id': 2,
          // add other fields as needed (first_name, last_name, username...)
        }),
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        // Created successfully.
        // NOTE: the server should ideally send a verification email if you rely on EmailVerificationScreen.
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
          ),
        );
        return;
      }

      // Handle known error payloads
      final body = resp.body.isNotEmpty ? json.decode(resp.body) : null;
      final message =
          (body is Map && (body['message'] ?? body['error']) != null)
              ? (body['message'] ?? body['error'])
              : 'Failed to create account';

      setState(() {
        _generalError = message;
      });
    } catch (e) {
      setState(() {
        _generalError = 'An unknown error occurred';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithProvider(
    Future<dynamic> Function() signInMethod,
  ) async {
    if (_isLoading) return;

    _clearErrors();
    setState(() => _isLoading = true);

    try {
      // Provided AuthServices may or may not implement social sign-ins.
      final result = await signInMethod();
      // If social sign-in returns a user-like object, navigate to verification or complete profile.
      if (result != null && mounted) {
        final email = (result is Map ? result['email'] : null) ?? '';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
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
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
            const TextSpan(text: " and "),
            TextSpan(
              text: "Privacy Policy",
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w600),
              recognizer: TapGestureRecognizer()..onTap = () {},
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
            : () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const StudentLoginScreen())),
        style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: Text(
          'Already have an account? Sign in',
          style: GoogleFonts.poppins(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600),
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildErrorContainer(_generalError),
            _buildEmailField(),
            _buildPasswordField(),
            _buildConfirmPasswordField(),
            _buildCreateAccountButton(),
            _buildDivider(),
            const SizedBox(height: 12),
            _buildTermsText(context),
            const SizedBox(height: 32),
            _buildLoginLink(),
            const SizedBox(height: 30),
          ]),
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
              child:
                  Divider(color: theme.colorScheme.outline.withOpacity(0.3))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("or",
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6)))),
          Expanded(
              child:
                  Divider(color: theme.colorScheme.outline.withOpacity(0.3))),
        ],
      ),
    );
  }
}
