import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import 'success_screen.dart';
import 'complete_profile_screen.dart';
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
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(email)
            .get();

        if (!mounted) return;
        final data = doc.data();
        final isVerified = currentUser.emailVerified;
        final status = data?['status'];

        if (status == "verified" && isVerified) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SuccessScreen()),
          );
        } else {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
          );
        }
      } else {
        if (!mounted) return;
        _showDialog("account_not_found".tr());
      }
    } catch (e) {
      debugPrint("Login error: $e");
      if (!mounted) return;
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
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.arrow_back_ios),
                    ),
                    const SizedBox(height: 30),
                    Image.asset('assets/images/bus_logo.png', width: 180),
                    const SizedBox(height: 40),
                    Text(
                      "login".tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "login_instruction".tr(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'email_hint'.tr(),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'password_hint'.tr(),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("or"),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SignInButton(
                      Buttons.Google,
                      text: "continue_google".tr(),
                      onPressed: () async {
                        final localContext = context;
                        final user = await AuthServices.signInWithGoogle();
                        if (!mounted || user == null) return;

                        final doc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.user?.email)
                            .get();

                        if (!mounted) return;
                        final data = doc.data();
                        final status = data?['status'];

                        if (status == 'verified') {
                          if (!mounted) return;
                          Navigator.pushReplacement(
                            localContext,
                            MaterialPageRoute(
                              builder: (_) => const SuccessScreen(),
                            ),
                          );
                        } else {
                          if (!mounted) return;
                          Navigator.pushReplacement(
                            localContext,
                            MaterialPageRoute(
                              builder: (_) => const CompleteProfileScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    SignInButton(
                      Buttons.Apple,
                      text: "continue_apple".tr(),
                      onPressed: () {
                        // Apple sign-in logic (to be implemented)
                      },
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: "terms_agree".tr(),
                        style: const TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: "terms_of_service".tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "privacy_policy".tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          child: Text("create_account".tr()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
