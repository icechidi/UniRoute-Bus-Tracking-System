// splash_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'success_screen.dart';
import 'role_selector_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import '../auth_services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minSplashDuration = Duration(seconds: 2);
  static const _firstLaunchKey = 'isFirstLaunch';
  static const _transitionDuration = Duration(milliseconds: 300);
  static const _maxRetries = 3;

  bool _showError = false;
  String? _errorMessage;
  int _retryCount = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final stopwatch = Stopwatch()..start();
    try {
      await Future.wait([
        _checkFirstLaunch(),
        _precacheResources(),
      ]);

      final user = await _checkAuthState();
      final remainingTime = _minSplashDuration - stopwatch.elapsed;

      if (remainingTime > Duration.zero) {
        await Future.delayed(remainingTime);
      }

      if (!mounted) return;
      _navigateBasedOnAuth(user);
    } catch (e) {
      if (!mounted) return;
      _handleInitializationError(e.toString());
    } finally {
      stopwatch.stop();
    }
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

    if (isFirstLaunch) {
      await prefs.setBool(_firstLaunchKey, false);
    }
  }

  Future<void> _precacheResources() async {
    try {
      await precacheImage(
          const AssetImage('assets/images/bus_logo.gif'), context);
    } catch (e) {
      debugPrint('Precache error: $e');
    }
  }

  Future<User?> _checkAuthState() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        final token = await AuthServices.getStoredToken();
        final email = await AuthServices.getStoredEmail();

        if (token != null && email != null) {
          final credential = GoogleAuthProvider.credential(idToken: token);
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          user = userCredential.user;
        }
      }
      return user;
    } catch (e) {
      return null;
    }
  }

  void _navigateBasedOnAuth(User? user) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: _transitionDuration,
        pageBuilder: (_, __, ___) =>
            user != null ? const SuccessScreen() : const RoleSelectorScreen(),
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

    _retryTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showError = false);

      if (_retryCount <= _maxRetries) {
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
              'assets/images/bus_logo.gif',
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
            title: Text('init_error_title'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error ?? 'Unknown error'),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                const Text('Attempting to recover...'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry Now'),
              ),
              TextButton(
                onPressed: onContinue,
                child: const Text('Continue Anyway'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
