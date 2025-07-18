import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/gestures.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('accept_terms_to_continue'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('email_already_in_use'.tr())),
        );
        return;
      }

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) throw Exception("User creation failed");

      await user.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'email': email,
        'uid': user.uid,
        'email_status': 'unverified',
        'account_status': 'incomplete',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: email),
        ),
      );
    } on FirebaseAuthException catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      if (!mounted) return;
      final message = switch (e.code) {
        'weak-password' => 'password_too_weak'.tr(),
        'invalid-email' => 'invalid_email_format'.tr(),
        'operation-not-allowed' => 'auth_not_allowed'.tr(),
        _ => 'auth_error_occurred'.tr(),
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('unknown_error_occurred'.tr())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "create_account".tr(),
      subtitle: "enter_email_to_signup".tr(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: buildInputDecoration('email_hint'),
              validator: AppValidators.email,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: buildInputDecoration('password_hint').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              validator: AppValidators.password,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration:
                  buildInputDecoration('confirm_password_hint').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_showConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword),
                ),
              ),
              validator: (value) => AppValidators.confirmPassword(
                  value, _passwordController.text),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) =>
                      setState(() => _acceptTerms = value ?? false),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'i_agree_to'.tr()),
                        TextSpan(
                          text: 'terms_of_service'.tr(),
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // TODO: Open terms
                            },
                        ),
                        TextSpan(text: 'and'.tr()),
                        TextSpan(
                          text: 'privacy_policy'.tr(),
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // TODO: Open privacy policy
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAccount,
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
                  child: Text("or".tr()),
                ),
                const Expanded(child: Divider(thickness: 1)),
              ],
            ),
            const SizedBox(height: 20),
            _buildSocialButton(
              text: "continue_google",
              icon: Image.asset('assets/images/google_logo.png',
                  width: 24, height: 24),
              onPressed: _signInWithGoogle,
            ),
            if (!kIsWeb)
              _buildSocialButton(
                text: "continue_apple",
                icon: const Icon(Icons.apple, color: Colors.white, size: 24),
                backgroundColor: Colors.black,
                borderColor: Colors.black,
                textColor: Colors.white,
                onPressed: _signInWithApple,
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
              ),
              child: Text(
                'already_have_account'.tr(),
                style:
                    GoogleFonts.poppins(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      final userCredential = await AuthServices.signInWithGoogle();
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
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('google_signin_failed'.tr())),
      );
    }
  }

  Future<void> _signInWithApple() async {
    try {
      final userCredential = await AuthServices.signInWithApple();
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
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('apple_signin_failed'.tr())),
      );
    }
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
      child: OutlinedButton.icon(
        icon: icon,
        label: Text(
          text.tr(),
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
