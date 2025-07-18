import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/common_widgets.dart'; // Assuming this contains buildInputDecoration()

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showDialog("fields_required".tr());
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showDialog("invalid_email".tr());
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Check if account exists in Firestore
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(email).get();
      if (!doc.exists) {
        _showDialog("no_account_found"
            .tr()); // Make sure to add this key in your localization
        return;
      }

      // Send reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showDialog("reset_link_sent".tr());
    } on FirebaseAuthException catch (e) {
      _showDialog(e.message ?? "reset_failed".tr());
    } catch (e) {
      _showDialog("unknown_error".tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("reset_password".tr(), style: GoogleFonts.poppins()),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text("ok".tr(), style: GoogleFonts.poppins()),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "forgot_password".tr(),
      subtitle: "reset_instruction".tr(),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: buildInputDecoration('email_hint'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetEmail,
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
                      "send_reset_link".tr(),
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
              "back_to_login".tr(),
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
