// File: widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

InputDecoration buildInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint.tr(),
    hintStyle: GoogleFonts.poppins(
      color: Colors.grey[600],
      fontSize: 14,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

Widget buildTermsText(BuildContext context) {
  return Text.rich(
    TextSpan(
      text: "terms_agree".tr(),
      style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
      children: [
        TextSpan(
          text: "terms_of_service".tr(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue),
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.pushNamed(context, '/termsOfService'),
        ),
        TextSpan(
          text: " and ",
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
        ),
        TextSpan(
          text: "privacy_policy".tr(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue),
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.pushNamed(context, '/privacyPolicy'),
        ),
      ],
    ),
    textAlign: TextAlign.center,
  );
}

class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
  });

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
              if (showBack)
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
                title,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
