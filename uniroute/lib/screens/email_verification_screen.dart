import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  String? _generatedCode;

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
  }

  /// Generates a random 6-digit code
  String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      _isSending = true;
      _canResend = false;
    });

    final code = _generateCode();
    _generatedCode = code;

    try {
      // 🔒 Store the code in Firestore temporarily
      await FirebaseFirestore.instance
          .collection('verifications')
          .doc(widget.email)
          .set({
        'code': code,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 🔧 For now, just print it (replace with backend email sender in real use)
      debugPrint("📧 Verification code sent to ${widget.email}: $code");

      await Future.delayed(
          const Duration(seconds: 10)); // Delay before enabling resend
      setState(() {
        _isSending = false;
        _canResend = true;
      });
    } catch (e) {
      debugPrint("❌ Failed to send code: $e");
      setState(() => _isSending = false);
    }
  }

  Future<void> _verifyCode() async {
    setState(() => _isVerifying = true);

    final inputCode = _codeController.text.trim();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('verifications')
          .doc(widget.email)
          .get();

      if (doc.exists && doc['code'] == inputCode) {
        // ✅ Update user's status as verified
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.email)
            .update({'status': 'verified'});

        // ❌ Optionally delete the code after success
        await FirebaseFirestore.instance
            .collection('verifications')
            .doc(widget.email)
            .delete();

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
                  label: _isSending
                      ? const Text("Sending...")
                      : Text("resend_email".tr()),
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
