// Flutter & Dart imports
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';

import 'success_screen.dart';

/// Screen responsible for email verification via OTP sent using EmailJS.
/// Code is stored in Firestore for secure verification and expires in 15 minutes.
class EmailVerificationScreen extends StatefulWidget {
  final String email; // Email address of the user to verify

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  // Text controller for 6-digit code input
  final TextEditingController _codeController = TextEditingController();

  // UI state tracking flags
  bool _isSending = false; // Tracks whether email is being sent
  bool _isVerifying = false; // Tracks whether code is being verified
  bool _canResend = false; // Tracks whether resend is currently allowed

  // Timer for resend cooldown management
  Timer? _resendCooldownTimer;
  int _resendCooldownSeconds = 60; // Time (in seconds) before resend allowed

  @override
  void initState() {
    super.initState();
    _sendVerificationCode(); // Automatically send code when screen is opened
  }

  @override
  void dispose() {
    _resendCooldownTimer?.cancel(); // Stop timer to prevent leaks
    _codeController.dispose(); // Dispose controller
    super.dispose();
  }

  /// Generates a random 6-digit OTP as a string
  String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // Range: 100000–999999
  }

  /// Formats expiry time into a human-readable string (e.g., 02:15 PM)
  String _formatExpiryTime(DateTime expiryTime) {
    return DateFormat('hh:mm a').format(expiryTime);
  }

  /// Starts a 60-second cooldown for the resend button
  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    setState(() {
      _resendCooldownSeconds = 60;
      _canResend = false;
    });

    // Countdown logic
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _resendCooldownSeconds--);
      }
    });
  }

  /// Sends OTP code via EmailJS and stores code + expiry in Firestore
  Future<void> _sendVerificationCode() async {
    setState(() {
      _isSending = true;
      _canResend = false;
    });

    final code = _generateCode();
    final expiry = DateTime.now().add(const Duration(minutes: 15));

    try {
      // Store code with expiration in Firestore
      await FirebaseFirestore.instance
          .collection('verifications')
          .doc(widget.email)
          .set({
        'code': code,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': expiry.toIso8601String(),
      });

      // Send email using EmailJS service
      final emailSent = await _sendEmailJs(
        email: widget.email,
        code: code,
        time: _formatExpiryTime(expiry),
      );

      if (emailSent) {
        _showInfo("verification_code_sent".tr());
        _startResendCooldown();
      } else {
        _showError("email_send_failed".tr());
      }
    } catch (e) {
      debugPrint("❌ Error sending code: $e");
      _showError("send_code_failed".tr());
    }

    setState(() => _isSending = false);
  }

  /// Verifies the entered OTP code against Firestore and updates user status
  Future<void> _verifyCode() async {
    setState(() => _isVerifying = true);

    final inputCode = _codeController.text.trim();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('verifications')
          .doc(widget.email)
          .get();

      if (!doc.exists) {
        _showError("code_expired_or_invalid".tr());
        return;
      }

      final storedCode = doc['code'];
      final expiresAt = DateTime.parse(doc['expiresAt']);

      // Check if code is expired
      if (DateTime.now().isAfter(expiresAt)) {
        await doc.reference.delete();
        _showError("code_expired".tr());
        return;
      }

      // Code is correct
      if (storedCode == inputCode) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.email)
            .update({'status': 'verified'}); // Mark user as verified

        await doc.reference.delete(); // Cleanup OTP record

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      } else {
        _showError("invalid_code".tr());
      }
    } catch (e) {
      debugPrint("❌ Error verifying code: $e");
      _showError("verification_failed".tr());
    }

    setState(() => _isVerifying = false);
  }

  /// Sends a POST request to EmailJS with OTP content
  Future<bool> _sendEmailJs({
    required String email,
    required String code,
    required String time,
  }) async {
    const serviceId = 'service_7vpri2c';
    const templateId = 'template_jfu83ld';
    const userId = '3MEjIrwOktOaswsrX';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'user_email': email,
          'passcode': code,
          'time': time,
        },
      }),
    );

    return response.statusCode == 200;
  }

  /// Shows an info SnackBar (blue)
  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  /// Shows an error SnackBar (red)
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
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

                // Instructional text
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

                // OTP input field
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "enter_code".tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Verify button
                ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("verify".tr()),
                ),
                const SizedBox(height: 20),

                // Resend button with countdown
                ElevatedButton.icon(
                  onPressed: _canResend ? _sendVerificationCode : null,
                  icon: const Icon(Icons.refresh),
                  label: Text(_isSending
                      ? "Sending..."
                      : _canResend
                          ? "resend_email".tr()
                          : "resend_in"
                              .tr(args: [_resendCooldownSeconds.toString()])),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
