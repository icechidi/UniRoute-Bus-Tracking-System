import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import 'success_screen.dart';
import 'complete_profile_screen.dart';
import 'email_verification_screen.dart';
import '../auth_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showDialog("fields_required".tr());
      return;
    }

    try {
      await AuthServices.signInWithEmail(email, password);
      if (!mounted) return;

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _showDialog("account_not_found".tr());
        return;
      }

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(email).get();

      if (!doc.exists) {
        _showDialog("account_not_found".tr());
        return;
      }

      final data = doc.data();
      final status = data?['status'];
      final isVerified = currentUser.emailVerified;

      if (status != 'verified') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
        );
      } else if (!isVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      }
    } catch (e) {
      _showDialog("account_not_found".tr());
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("login_failed".tr()),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("ok".tr()),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 20),
              Image.asset('assets/images/bus_logo.png', width: 140),
              const SizedBox(height: 24),
              Text(
                "login".tr(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "login_instruction".tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'email_hint'.tr(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'password_hint'.tr(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "continue".tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white, // ✅ Make text white
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
                    child:
                        Text("or".tr(), style: const TextStyle(fontSize: 14)),
                  ),
                  const Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),
              SignInButton(
                Buttons.GoogleDark,
                text: "continue_google".tr(),
                onPressed: () async {
                  final userCredential = await AuthServices.signInWithGoogle();
                  final user = userCredential?.user;

                  if (!mounted || user == null) return;

                  final doc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.email)
                      .get();

                  if (!doc.exists) {
                    _showDialog("account_not_found".tr());
                    return;
                  }

                  final data = doc.data();
                  final status = data?['status'];
                  final isVerified = user.emailVerified;

                  if (status != 'verified') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CompleteProfileScreen()),
                    );
                  } else if (!isVerified) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EmailVerificationScreen(email: user.email!),
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SuccessScreen()),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              SignInButton(
                Buttons.AppleDark,
                text: "continue_apple".tr(),
                onPressed: () {
                  // TODO: Implement Apple sign-in
                },
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text.rich(
                  TextSpan(
                    text: "terms_agree".tr(),
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: "terms_of_service".tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const TextSpan(text: " and "),
                      TextSpan(
                        text: "privacy_policy".tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
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
                    child: Text("forgot_password".tr()),
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
                    child: Text("create_account".tr()),
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
