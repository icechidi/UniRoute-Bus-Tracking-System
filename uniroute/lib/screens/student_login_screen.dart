import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../utils/platform_utils.dart';
import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import 'success_screen.dart';
import 'complete_profile_screen.dart';
import 'email_verification_screen.dart';
import '../auth_services.dart';
import '../widgets/common_widgets.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showDialog("fields_required".tr());
      return;
    }

    if (!EmailValidator.validate(email)) {
      _showDialog("invalid_email".tr());
      return;
    }

    if (password.length < 6) {
      _showDialog("password_too_short".tr());
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthServices.signInWithEmail(email, password);
      if (!mounted) return;
      await _handleAuthSuccess(FirebaseAuth.instance.currentUser);
    } on FirebaseAuthException catch (e) {
      _showDialog(e.message ?? "login_failed".tr());
    } catch (e) {
      _showDialog("login_failed".tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuthSuccess(User? user) async {
    if (!mounted || user == null || user.email == null) {
      _showDialog("account_not_found".tr());
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (!doc.exists) {
        _showDialog("account_not_found".tr());
        return;
      }

      final status = doc.data()?['status'];
      if (status != 'verified') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
        );
      } else if (!user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: user.email!),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      }
    } catch (e) {
      _showDialog("login_failed".tr());
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("login_failed".tr(), style: GoogleFonts.poppins()),
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

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "login".tr(),
      subtitle: "login_instruction".tr(),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: buildInputDecoration('email_hint'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: buildInputDecoration('password_hint').copyWith(
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _loginWithEmail,
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
              await _handleAuthSuccess(userCredential?.user);
            },
          ),
          // Apple Sign-In Button (using platform utils)
          if (isAppleSignInAvailable)
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
                await _handleAuthSuccess(userCredential?.user);
              },
            ),
          const SizedBox(height: 20),
          buildTermsText(context),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  "forgot_password".tr(),
                  style: GoogleFonts.poppins(),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAccountScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  "create_account".tr(),
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}