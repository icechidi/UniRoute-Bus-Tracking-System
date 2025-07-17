import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _success = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    final passwordRegex =
        RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$&*~]).{6,}$');

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showErrorDialog("fields_required".tr());
      return;
    }
    if (!emailRegex.hasMatch(email)) {
      _showErrorDialog("invalid_email".tr());
      return;
    }
    if (!passwordRegex.hasMatch(password)) {
      _showErrorDialog("invalid_password".tr());
      return;
    }
    if (password != confirm) {
      _showErrorDialog("passwords_do_not_match".tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create the user and handle 'email-already-in-use' in the exception
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.email)
          .set({
        'email': email,
        'status': 'unverified',
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user?.uid,
      });

      setState(() => _success = true);
      _animationController.forward();

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/additionalInfo');
    } on FirebaseAuthException catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      String errorMessage = "signup_failed".tr();

      if (e.code == 'email-already-in-use') {
        errorMessage = "user_already_exists".tr();
      } else if (e.code == 'weak-password') {
        errorMessage = "weak_password".tr();
      } else if (e.code == 'invalid-email') {
        errorMessage = "invalid_email".tr();
      }

      _showErrorDialog(errorMessage);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      _showErrorDialog("unexpected_error".tr());
      debugPrint("Error during sign up: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      late UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        userCredential = await auth.signInWithPopup(googleProvider);
      } else {
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          setState(() => _isLoading = false);
          return; // User canceled the sign-in
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) throw Exception("Google sign-in failed - no user");

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .set({
          'email': user.email,
          'status': 'unverified',
          'createdAt': FieldValue.serverTimestamp(),
          'uid': user.uid,
        });

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/additionalInfo');
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      if (e.code != 'ERROR_ABORTED_BY_USER') {
        // Ignore canceled sign-in
        _showErrorDialog("google_signin_failed".tr());
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      _showErrorDialog("google_signin_failed".tr());
      debugPrint("Google sign-in error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          title: Text("error".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("ok".tr()),
            ),
          ],
        ),
      ),
    );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 8),
                Image.asset('assets/images/bus_logo.png', height: 120),
                const SizedBox(height: 16),
                Text(
                  "create_account".tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "enter_email_to_signup".tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email@domain.com",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  decoration: InputDecoration(
                    hintText: "Re-type Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _createAccount,
                          child: Text(
                            "continue".tr(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),

                // OR Divider
                Row(
                  children: [
                    const Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "or",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider(thickness: 1)),
                  ],
                ),

                const SizedBox(height: 16),

                SignInButton(
                  Buttons.Google,
                  text: "continue_google".tr(),
                  onPressed: _isLoading
                      ? () {}
                      : () {
                          _signInWithGoogle();
                        },
                ),
                const SizedBox(height: 8),
                SignInButton(
                  Buttons.Apple,
                  text: "continue_apple".tr(),
                  onPressed: () {
                    if (!_isLoading) {
                      // Apple sign-in logic to be implemented
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Tappable Terms & Privacy
                Text.rich(
                  TextSpan(
                    text: "By clicking continue, you agree to our ",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    children: [
                      TextSpan(
                        text: "Terms of Service",
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/termsOfService');
                          },
                      ),
                      const TextSpan(text: " and "),
                      TextSpan(
                        text: "Privacy Policy",
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/privacyPolicy');
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                if (_success)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Lottie.asset(
                      'assets/animations/success.json',
                      width: 120,
                      repeat: false,
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
