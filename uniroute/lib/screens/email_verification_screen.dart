import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/common_widgets.dart';
import 'complete_profile_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _verificationTimer;
  bool _isLoading = false;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail(forceSend: true);
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Send verification email regardless of emailVerified status (forceSend = true)
  Future<void> _sendVerificationEmail({bool forceSend = false}) async {
    setState(() {
      _isLoading = true;
      _resendCooldown = 60;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Always send email if forced OR if not verified yet
        if (forceSend || !user.emailVerified) {
          await user.sendEmailVerification();
          _startCooldownTimer();
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startVerificationCheck() {
    _verificationTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _checkVerificationStatus(),
    );
  }

  Future<void> _checkVerificationStatus() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user?.emailVerified ?? false) {
        _verificationTimer?.cancel();

        final email = user?.email;
        if (email != null) {
          // ✅ Update Firestore email_status to "verified"
          await FirebaseFirestore.instance
              .collection('users')
              .doc(email)
              .update({'email_status': 'verified'});
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const CompleteProfileScreen(),
            ),
          );
        }
      }
    } catch (_) {
      // Ignore silently
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_resendCooldown <= 0) {
          timer.cancel();
        } else {
          setState(() => _resendCooldown--);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "verify_email".tr(),
      subtitle: "verification_sent_to".tr(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.mark_email_read_outlined,
            size: 80,
            color: Colors.black87,
          ),
          const SizedBox(height: 24),
          Text(
            widget.email,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "check_inbox_instructions".tr(),
            style: GoogleFonts.poppins(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _resendCooldown > 0 || _isLoading
                  ? null
                  : () => _sendVerificationEmail(forceSend: true),
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
                      _resendCooldown > 0
                          ? "resend_in_seconds"
                              .tr(args: [_resendCooldown.toString()])
                          : "resend_email".tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "use_different_email".tr(),
              style: GoogleFonts.poppins(
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
