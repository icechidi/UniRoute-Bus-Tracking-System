import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/common_widgets.dart';
import '../utils/validators.dart';
import '../constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _generalError;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _clearMessages() {
    setState(() {
      _generalError = null;
      _successMessage = null;
    });
  }

  Future<void> _sendResetEmail() async {
    _clearMessages();

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() => _isLoading = true);

    try {
      // Check if account exists in Firestore
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(email)
          .get();

      if (!doc.exists) {
        setState(() {
          _generalError = "No account found with this email address.";
        });
        return;
      }

      // Send reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() {
        _successMessage =
            "Password reset link sent to your email. Please check your inbox.";
      });

      // Clear the email field after successful send
      _emailController.clear();
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      _handleFirebaseAuthError(e);
    } catch (e) {
      print("General exception: $e");
      setState(() {
        _generalError = "Failed to send reset email. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        setState(() {
          _generalError = "No account found with this email address.";
        });
        break;
      case 'invalid-email':
        setState(() {
          _generalError = "Invalid email address format.";
        });
        break;
      case 'user-disabled':
        setState(() {
          _generalError =
              "This account has been disabled. Please contact support.";
        });
        break;
      case 'too-many-requests':
        setState(() {
          _generalError = "Too many requests. Please try again later.";
        });
        break;
      case 'network-request-failed':
        setState(() {
          _generalError = "Network error. Please check your connection.";
        });
        break;
      default:
        setState(() {
          _generalError =
              e.message ?? "Failed to send reset email. Please try again.";
        });
    }
  }

  Widget _buildErrorContainer(String? error) {
    if (error == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withOpacity(0.1),
        border: Border.all(
          color: AppConstants.errorColor.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cornerRadius),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppConstants.errorColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppConstants.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContainer(String? message) {
    if (message == null) return const SizedBox.shrink();

    const successColor = Colors.green;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: successColor.withOpacity(0.1),
        border: Border.all(
          color: successColor.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cornerRadius),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: successColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScaffold(
      title: "Forgot Password",
      subtitle:
          "Enter your email address and we'll send you a link to reset your password",
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error/Success Message Display
              _buildErrorContainer(_generalError),
              _buildSuccessContainer(_successMessage),

              // Email Field
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  validator: AppValidators.email,
                  onFieldSubmitted: (_) => _sendResetEmail(),
                  onChanged: (_) => _clearMessages(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: buildInputDecoration('Email').copyWith(
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),

              // Send Reset Link Button
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Send Reset Link",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              // Back to Login Button
              Container(
                margin: const EdgeInsets.only(bottom: 30),
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Back to Login',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
