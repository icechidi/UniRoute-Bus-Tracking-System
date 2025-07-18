// Flutter & Dart imports
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

import 'success_screen.dart';

/// Screen responsible for verifying email using Firebase Auth built-in flow.
class EmailVerificationScreen extends StatefulWidget {
  final String email; // Email address of the user to verify

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _emailCheckTimer;
  bool _canResend = false;
  int _resendCooldownSeconds = 60;
  Timer? _resendCooldownTimer;

  @override
  void initState() {
    super.initState();
    _sendFirebaseVerification();
    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  /// Sends verification email via Firebase Auth
  Future<void> _sendFirebaseVerification() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && !user.emailVerified) {
      setState(() => _canResend = false);
      await user.sendEmailVerification();
      _showInfo("verification_code_sent".tr());
      _startResendCooldown();
    }
  }

  /// Continuously checks if the user's email has been verified
  void _startEmailVerificationCheck() {
    _emailCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      if (user != null && user.emailVerified) {
        timer.cancel();
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.email)
            .update({'status': 'verified'});
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      }
    });
  }

  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    setState(() {
      _resendCooldownSeconds = 60;
      _canResend = false;
    });

    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _resendCooldownSeconds--);
      }
    });
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  /// Builds the main UI for email verification
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email, size: 60, color: Colors.black87),
                const SizedBox(height: 20),

                Text(
                  "check_email_instruction".tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _canResend ? _sendFirebaseVerification : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _canResend ? Colors.black : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _canResend
                        ? "resend_email".tr()
                        : "resend_in".tr(args: [_resendCooldownSeconds.toString()]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
