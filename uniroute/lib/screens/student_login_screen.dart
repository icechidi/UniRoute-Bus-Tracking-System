import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

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
        print("User doc does NOT exist for email: ${user.email}");
        // No account doc → must create account
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
        );
        return;
      }

      final data = doc.data() ?? {};
      print('User doc data: $data');

      final emailStatus = (data['email_status'] ?? '').toString().toLowerCase();
      final accountStatus =
          (data['account_status'] ?? '').toString().toLowerCase();

      print('email_status: $emailStatus, account_status: $accountStatus');

      // If email_status missing or empty, treat as unverified (force verification)
      if (emailStatus.isEmpty || emailStatus == 'unverified') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: user.email!),
          ),
        );
        return;
      }

      // If account_status missing or empty, treat as incomplete (force profile completion)
      if (accountStatus.isEmpty || accountStatus == 'incomplete') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
        );
        return;
      }

      // If email_status verified and account_status complete proceed
      if (emailStatus == 'verified' && accountStatus == 'complete') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
        return;
      }

      // For any other unknown cases fallback to create account (safe fallback)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
      );
    } catch (e, stack) {
      print('Error in _handleAuthSuccess: $e\n$stack');
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: AppValidators.email,
              decoration: buildInputDecoration('email_hint'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              validator: AppValidators.password,
              decoration: buildInputDecoration('password_hint').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _loginWithEmail();
                        }
                      },
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
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
      ),
    );
  }
}
