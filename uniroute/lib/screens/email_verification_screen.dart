// email_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Timer? _cooldownTimer;

  bool _isLoading = false;
  int _resendCooldown = 60;

  bool get _canResend => _resendCooldown <= 0 && !_isLoading;

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

  Future<void> _sendVerificationEmail({bool forceSend = false}) async {
    setState(() {
      _isLoading = true;
      _resendCooldown = 60;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && (forceSend || !user.emailVerified)) {
        await user.sendEmailVerification();
        _startCooldownTimer();
      }
    } catch (_) {
      // Ignore error for UX
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  void _startVerificationCheck() {
    _verificationTimer = Timer.periodic(
        const Duration(seconds: 3), (timer) => _checkVerificationStatus());
  }

  Future<void> _checkVerificationStatus() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user?.emailVerified ?? false) {
        _verificationTimer?.cancel();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
          );
        }
      }
    } catch (_) {
      // Ignore error for UX
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "verify_email".tr(),
      subtitle: "verification_sent_to".tr(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.mark_email_read_outlined,
              size: 80, color: Colors.black87),
          const SizedBox(height: 24),
          Text(
            widget.email,
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
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
              onPressed: _canResend
                  ? () => _sendVerificationEmail(forceSend: true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
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
              style: GoogleFonts.poppins(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}
