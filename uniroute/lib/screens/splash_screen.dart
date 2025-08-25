// splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'role_selector_screen.dart';
import '../auth_services.dart';
import '../constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showError = false;
  String? _errorMessage;
  int _retryCount = 0;
  Timer? _retryTimer;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.wait([
        _checkFirstLaunch(),
        _precacheResources(),
        _checkAuthState(), // Now safe and correct
      ]);

      _completeInitialization();
    } catch (e) {
      if (!mounted) return;
      _handleInitializationError(e.toString());
    }
  }

  Future<void> _completeInitialization() async {
    final remainingTime = AppConstants.minSplashDuration - _stopwatch.elapsed;
    if (remainingTime > Duration.zero) {
      await Future.delayed(remainingTime);
    }

    if (!mounted) return;
    _navigateBasedOnAuth(FirebaseAuth.instance.currentUser);
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(AppConstants.firstLaunchKey) ?? true;
    if (isFirstLaunch) {
      await prefs.setBool(AppConstants.firstLaunchKey, false);
    }
  }

  Future<void> _precacheResources() async {
    try {
      await precacheImage(
        const AssetImage(AppConstants.busLogoPath),
        context,
      );
    } catch (e) {
      debugPrint('Precache error: $e');
    }
  }

  // ✅ Fixed: Removed reliance on getStoredToken/getStoredEmail
  Future<void> _checkAuthState() async {
    // Firebase automatically restores the user session
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return; // Already signed in
    }

    // Optionally check if user wanted to stay signed in
    final shouldKeepSignedIn = await AuthServices.shouldKeepSignedIn();
    if (!shouldKeepSignedIn) {
      return;
    }

    // Firebase will handle session restore — no need to manually sign in
    // If user is still null, proceed to login screen
  }

  void _navigateBasedOnAuth(User? user) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: AppConstants.transitionDuration,
        pageBuilder: (_, __, ___) =>
            user != null ? const HomeScreen() : const RoleSelectorScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _handleInitializationError(String error) {
    _retryCount++;
    setState(() {
      _errorMessage = error;
      _showError = true;
    });

    _retryTimer = Timer(AppConstants.retryDelay, () {
      if (!mounted) return;
      setState(() => _showError = false);

      if (_retryCount <= AppConstants.maxRetries) {
        _initializeApp();
      } else {
        _navigateBasedOnAuth(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              AppConstants.busLogoPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_bus,
                size: 200,
                color: Colors.blue,
              ),
            ),
          ),
          if (_showError)
            _ErrorOverlay(
              error: _errorMessage,
              onRetry: _initializeApp,
              onContinue: () => _navigateBasedOnAuth(null),
            ),
        ],
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  const _ErrorOverlay({
    required this.error,
    required this.onRetry,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: AlertDialog(
            title: const Text(AppConstants.initializationErrorTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error ?? AppConstants.unknownError),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                const Text(AppConstants.attemptingRecovery),
              ],
            ),
            actions: [
              TextButton(
                onPressed: onContinue,
                child: const Text(AppConstants.continueAnyway),
              ),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text(AppConstants.retryNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
