import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'success_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSending = false;
  bool _isVerifying = false;
  bool _canResend = false;
  Timer? _resendCooldownTimer;
  int _resendCooldownSeconds = 60;

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
  }

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  /// 🔢 Generate random 6-digit code
  String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// 🕒 Format readable expiration
  String _formatExpiryTime(DateTime expiryTime) {
    return DateFormat('hh:mm a').format(expiryTime);
  }

  /// 🌀 Start cooldown after sending
  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    setState(() {
      _resendCooldownSeconds = 60;
      _canResend = false;
    });

    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      } else {
        setState(() {
          _resendCooldownSeconds--;
        });
      }
    });
  }

  /// 📧 Send OTP via EmailJS and store in Firestore
  Future<void> _sendVerificationCode() async {
    setState(() {
      _isSending = true;
      _canResend = false;
    });

    final code = _generateCode();
    final expiry = DateTime.now().add(const Duration(minutes: 15));

    try {
      // 🔄 Save OTP in Firestore (overwrites existing)
      await FirebaseFirestore.instance
          .collection('verifications')
          .doc(widget.email)
          .set({
        'code': code,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': expiry.toIso8601String(),
      });

      // 📤 Send via EmailJS
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

  /// ✅ Verify the code
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

      if (DateTime.now().isAfter(expiresAt)) {
        await doc.reference.delete();
        _showError("code_expired".tr());
        return;
      }

      if (storedCode == inputCode) {
        // 🎉 Verified!
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.email)
            .update({'status': 'verified'});

        await doc.reference.delete();

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

  /// 🔵 Styled info message
  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  /// 🔴 Styled error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  /// 🌐 Send email using EmailJS API
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
