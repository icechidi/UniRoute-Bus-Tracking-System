import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import '../auth_services.dart';
import 'success_screen.dart';

class DriverLoginScreen extends StatelessWidget {
  const DriverLoginScreen({super.key});

  Future<void> _handleGoogleLogin(BuildContext context) async {
    final user = await AuthServices.signInWithGoogle();
    if (!context.mounted) return;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuccessScreen()),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Login Failed"),
          content: const Text("Something went wrong. Try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Image.asset('assets/images/bus_logo.png', width: 180),
              const SizedBox(height: 40),
              const Text("Login",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Sign in using your Google account",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              SignInButton(
                Buttons.Google,
                text: "Continue with Google",
                onPressed: () => _handleGoogleLogin(context),
              ),
              const SizedBox(height: 16),
              SignInButton(
                Buttons.Apple,
                text: "Continue with Apple",
                onPressed: () {
                  // Apple sign-in logic
                },
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  text: "By logging in, you agree to our ",
                  style: TextStyle(color: Colors.grey),
                  children: [
                    TextSpan(
                      text: "Terms of Service",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    TextSpan(text: " and "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
