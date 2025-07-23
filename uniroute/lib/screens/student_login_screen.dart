// student_login_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';

import '../utils/platform_utils.dart';
import '../auth_services.dart';
import '../widgets/common_widgets.dart';
import '../utils/validators.dart';

import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import 'success_screen.dart';
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
  bool _keepSignedIn = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final userCredential =
          await AuthServices.signInWithEmail(email, password, _keepSignedIn);
      if (userCredential != null) {
        await _handleAuthSuccess(userCredential.user);
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
    } catch (e) {
      _showErrorDialog("login_failed".tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await AuthServices.signInWithGoogle();
      if (userCredential != null) {
        await _handleAuthSuccess(userCredential.user);
      }
    } catch (e) {
      _showErrorDialog("google_signin_failed".tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithApple() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await AuthServices.signInWithApple();
      if (userCredential != null) {
        await _handleAuthSuccess(userCredential.user);
      }
    } catch (e) {
      _showErrorDialog("apple_signin_failed".tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuthSuccess(User? user) async {
    if (!mounted || user == null) return;

    try {
      if (!user.emailVerified) {
        _navigateToEmailVerification(user.email!);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (!userDoc.exists) {
        _navigateToCompleteProfile();
        return;
      }

      final accountStatus = userDoc.data()?['account_status'] ?? 'incomplete';
      switch (accountStatus) {
        case 'incomplete':
          _navigateToCompleteProfile();
          break;
        case 'complete':
          _navigateToSuccess();
          break;
        case 'suspended':
          _showErrorDialog("account_suspended".tr());
          await FirebaseAuth.instance.signOut();
          break;
        case 'pending':
          _showErrorDialog("account_pending_approval".tr());
          await FirebaseAuth.instance.signOut();
          break;
        default:
          _showErrorDialog("unexpected_account_status".tr());
      }
    } catch (e) {
      _showErrorDialog("login_failed".tr());
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        _showAccountNotFoundDialog();
        return;
      case 'wrong-password':
        _showErrorDialog("incorrect_password".tr());
        break;
      case 'user-disabled':
        _showErrorDialog("account_disabled".tr());
        break;
      case 'too-many-requests':
        _showErrorDialog("too_many_attempts".tr());
        break;
      case 'invalid-email':
        _showErrorDialog("invalid_email_format".tr());
        break;
      case 'network-request-failed':
        _showErrorDialog("network_error".tr());
        break;
      default:
        _showErrorDialog(e.message ?? "login_failed".tr());
    }
  }

  void _navigateToEmailVerification(String email) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EmailVerificationScreen(email: email),
      ),
    );
  }

  void _navigateToCompleteProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
    );
  }

  void _navigateToSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessScreen()),
    );
  }

  void _showAccountNotFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "account_not_found".tr(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "no_account_exists".tr(),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "cancel".tr(),
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateAccountScreen(),
                ),
              );
            },
            child: Text(
              "create_account".tr(),
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "error".tr(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ok".tr(), style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required Widget icon,
    required VoidCallback? onPressed,
    Color backgroundColor = Colors.white,
    Color borderColor = Colors.grey,
    Color textColor = Colors.black87,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: borderColor.withOpacity(0.3), width: 1),
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

  Widget _buildTermsText(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text.rich(
        TextSpan(
          text: "by_clicking_continue".tr(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
            height: 1.4,
          ),
          children: [
            const TextSpan(text: " "),
            TextSpan(
              text: "terms_of_service".tr(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Navigate to terms
                },
            ),
            TextSpan(
              text: " ${"and".tr()} ",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            TextSpan(
              text: "privacy_policy".tr(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
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

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "login".tr(),
      subtitle: "login_instruction".tr(),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email Field
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  validator: AppValidators.email,
                  decoration: buildInputDecoration('email_hint').copyWith(
                    prefixIcon:
                        Icon(Icons.email_outlined, color: Colors.grey[600]),
                  ),
                ),
              ),

              // Password Field
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  validator: AppValidators.password,
                  onFieldSubmitted: (_) => _loginWithEmail(),
                  decoration: buildInputDecoration('password_hint').copyWith(
                    prefixIcon:
                        Icon(Icons.lock_outline, color: Colors.grey[600]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: _isLoading
                          ? null
                          : () =>
                              setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
              ),

              // Keep signed in checkbox
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    Checkbox(
                      value: _keepSignedIn,
                      onChanged: _isLoading
                          ? null
                          : (v) => setState(() => _keepSignedIn = v ?? true),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () =>
                                setState(() => _keepSignedIn = !_keepSignedIn),
                        child: Text(
                          'keep_me_signed_in'.tr(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              ),

              // OR Divider
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "or".tr(),
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
              ),

              // Social Login Buttons
              _buildSocialButton(
                text: "continue_google",
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: _loginWithGoogle,
              ),

              if (isAppleSignInAvailable)
                _buildSocialButton(
                  text: "continue_apple",
                  icon: const Icon(Icons.apple, size: 24, color: Colors.white),
                  backgroundColor: Colors.black,
                  borderColor: Colors.black,
                  textColor: Colors.white,
                  onPressed: _loginWithApple,
                ),

              const SizedBox(height: 8),
              _buildTermsText(context),
              const SizedBox(height: 24),

              // Forgot Password / Create Account Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        "forgot_password".tr(),
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateAccountScreen(),
                                ),
                              );
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        "create_account".tr(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
