import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
// Added for WidgetsBinding

import '../utils/platform_utils.dart';
import '../auth_services.dart';
import '../widgets/common_widgets.dart';
import '../utils/validators.dart';
import '../constants.dart';

import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'complete_profile_screen.dart';
import 'email_verification_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  bool _keepSignedIn = false; // Changed to false to match UI

  // Simplified error handling - only general error needed
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _generalError = null;
    });
  }

  Future<void> _loginWithEmail() async {
    _clearErrors();

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final userCredential =
          await AuthServices.signInWithEmail(email, password, _keepSignedIn);
      if (userCredential != null) {
        await _handleAuthSuccess(userCredential.user);
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      _handleFirebaseAuthError(e);
    } catch (e) {
      print("General exception: $e");
      setState(() {
        _generalError = "Login failed. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    _clearErrors();
    setState(() => _isLoading = true);
    try {
      final userCredential = await AuthServices.signInWithGoogle();
      if (userCredential != null) {
        await _handleAuthSuccess(userCredential.user);
      }
    } catch (e) {
      setState(() {
        _generalError = "Google sign-in failed. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithApple() async {
    _clearErrors();
    setState(() => _isLoading = true);
    try {
      final userCredential = await AuthServices.signInWithApple();
      if (userCredential != null) {
        await _handleAuthSuccess(userCredential.user);
      }
    } catch (e) {
      setState(() {
        _generalError = "Apple sign-in failed. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuthSuccess(User? user) async {
    if (!mounted || user == null) return;

    try {
      // Check email verification first
      if (!user.emailVerified) {
        await _navigateToEmailVerification(user.email!);
        return;
      }

      // Check if user document exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.email)
          .get();

      if (!userDoc.exists) {
        await _navigateToCompleteProfile();
        return;
      }

      // Check account status
      final userData = userDoc.data()!;
      final accountStatus = userData['account_status'] ?? 'incomplete';

      switch (accountStatus) {
        case 'incomplete':
          await _navigateToCompleteProfile();
          break;
        case 'complete':
          await _navigateToSuccess();
          break;
        case 'suspended':
          setState(() {
            _generalError =
                "Your account has been suspended. Please contact support.";
          });
          await FirebaseAuth.instance.signOut();
          break;
        case 'pending':
          setState(() {
            _generalError =
                "Your account is pending approval. Please wait for confirmation.";
          });
          await FirebaseAuth.instance.signOut();
          break;
        default:
          setState(() {
            _generalError =
                "Unexpected account status. Please contact support.";
          });
          await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      setState(() {
        _generalError = "Failed to verify account status. Please try again.";
      });
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    print("Handling Firebase Auth Error: ${e.code}");

    switch (e.code) {
      case 'user-not-found':
        setState(() {
          _generalError = "No account found with this email address.";
        });
        // Use WidgetsBinding to ensure the dialog shows after the build cycle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showAccountNotFoundDialog();
          }
        });
        break;
      case 'wrong-password':
      case 'invalid-credential':
        setState(() {
          _generalError =
              "Invalid email or password. Please check your credentials.";
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
          _generalError = "Too many failed attempts. Please try again later.";
        });
        break;
      case 'network-request-failed':
        setState(() {
          _generalError = "Network error. Please check your connection.";
        });
        break;
      case 'channel-error':
        setState(() {
          _generalError = "Please fill in all required fields.";
        });
        break;
      default:
        setState(() {
          _generalError = e.message ?? "Login failed. Please try again.";
        });
    }
  }

  Future<void> _navigateToEmailVerification(String email) async {
    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EmailVerificationScreen(email: email),
      ),
    );
  }

  Future<void> _navigateToCompleteProfile() async {
    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
    );
  }

  Future<void> _navigateToSuccess() async {
    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _navigateToCreateAccount() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateAccountScreen(),
      ),
    );
  }

  void _navigateToForgotPassword() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  void _showAccountNotFoundDialog() {
    print("Attempting to show account not found dialog");

    if (!mounted) {
      print("Widget not mounted, cannot show dialog");
      return;
    }

    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cornerRadius),
          ),
          title: Text(
            "Account Not Found",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            "No account exists with this email address. Would you like to create a new account?",
            style: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  _navigateToCreateAccount();
                }
              },
              child: Text(
                "Create Account",
                style: GoogleFonts.poppins(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      print("Dialog closed");
    }).catchError((error) {
      print("Dialog error: $error");
    });
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

  Widget _buildSocialButton({
    required String text,
    required Widget icon,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? borderColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.surface,
          padding:
              const EdgeInsets.symmetric(vertical: 16), // Slightly more padding
          side: BorderSide(
            color: (borderColor ?? theme.colorScheme.outline).withOpacity(0.2),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // More rounded
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textColor ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: Text.rich(
        TextSpan(
          text: "By clicking continue, you agree to our ",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: "Terms of Service",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Navigate to terms
                },
            ),
            const TextSpan(text: " and "),
            TextSpan(
              text: "Privacy Policy",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Navigate to privacy
                },
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScaffold(
      title: "Login",
      subtitle:
          "Enter your email to sign in for this app", // Updated to match UI
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // General Error Display
              _buildErrorContainer(_generalError),

              // Email Field
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  validator: AppValidators.email,
                  onChanged: (_) => _clearErrors(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration:
                      buildInputDecoration('Email, Username or Student ID')
                          .copyWith(
                    // Updated placeholder
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),

              // Password Field
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  validator: AppValidators.password,
                  onFieldSubmitted: (_) => _loginWithEmail(),
                  onChanged: (_) => _clearErrors(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: buildInputDecoration('Password').copyWith(
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () =>
                              setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
              ),

              // Keep signed in checkbox
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    Checkbox(
                      value: _keepSignedIn,
                      onChanged: _isLoading
                          ? null
                          : (v) => setState(() => _keepSignedIn = v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: Colors.black,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () =>
                                setState(() => _keepSignedIn = !_keepSignedIn),
                        child: Text(
                          "Keep me signed in",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Login Button
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginWithEmail,
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
                          "Continue",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              // OR Divider
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "or",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),

              // Social Login Buttons
              _buildSocialButton(
                text: "Continue with Google",
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: _loginWithGoogle,
              ),

              if (isAppleSignInAvailable)
                _buildSocialButton(
                  text: "Continue with Apple",
                  icon: const Icon(Icons.apple, size: 24, color: Colors.white),
                  backgroundColor: Colors.black,
                  borderColor: Colors.black,
                  textColor: Colors.white,
                  onPressed: _loginWithApple,
                ),

              const SizedBox(height: 12),
              _buildTermsText(context),
              const SizedBox(height: 32),

              // Bottom Buttons - Updated layout to match UI
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : _navigateToForgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : _navigateToCreateAccount,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Create an Account",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
