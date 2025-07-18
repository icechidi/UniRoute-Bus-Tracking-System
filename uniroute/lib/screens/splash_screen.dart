import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For auth checks
import 'success_screen.dart'; // Existing home screen
import 'role_selector_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Constants
  static const _minSplashDuration = Duration(seconds: 2); // Minimum splash time
  static const _logoSize = 200.0;
  static const _firstLaunchKey = 'isFirstLaunch';
  static const _transitionDuration = Duration(milliseconds: 300);

  // State variables
  double _loadingProgress = 0;
  String _loadingStatus = 'splash_initializing'.tr();
  bool _showError = false;
  Exception? _lastError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Main initialization pipeline
  Future<void> _initializeApp() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Track initialization progress
      _updateProgress(0.1, 'Checking first launch...');
      await _checkFirstLaunch();

      _updateProgress(0.3, 'Loading resources...');
      await _precacheResources();

      _updateProgress(0.5, 'Checking authentication...');
      final user = await _checkAuthState();

      _updateProgress(0.8, 'Finalizing...');

      // Ensure minimum splash duration
      final remainingTime = _minSplashDuration - stopwatch.elapsed;
      if (remainingTime > Duration.zero) {
        await Future.delayed(remainingTime);
      }

      if (!mounted) return;
      _updateProgress(1.0, 'Ready!');
      await Future.delayed(const Duration(milliseconds: 300)); // Smooth finish

      _navigateBasedOnAuth(user);
    } catch (e) {
      if (!mounted) return;
      _handleInitializationError(e as Exception);
    } finally {
      stopwatch.stop();
    }
  }

  /// Updates progress indicators
  void _updateProgress(double progress, String status) {
    if (!mounted) return;
    setState(() {
      _loadingProgress = progress;
      _loadingStatus = status;
    });
  }

  /// First launch setup
  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

    if (isFirstLaunch) {
      await prefs.setBool(_firstLaunchKey, false);
      // Example first-time setup:
      await prefs.setString('language', 'en');
    }
  }

  /// Preloads critical resources
  Future<void> _precacheResources() async {
    await Future.wait([
      precacheImage(const AssetImage('assets/images/bus_logo.png'), context),
      // precacheImage(AssetImage('assets/images/map_background.png'), context),
    ]);
  }

  /// Checks current auth state
  Future<User?> _checkAuthState() async {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint('Auth check error: $e');
      return null; // Fallback if auth check fails
    }
  }

  /// Navigation logic based on auth state
  void _navigateBasedOnAuth(User? user) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: _transitionDuration,
        pageBuilder: (_, __, ___) {
          if (user != null) {
            return const SuccessScreen(); // Already logged in
          } else {
            return const RoleSelectorScreen(); // New/guest user
          }
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Comprehensive error handling
  void _handleInitializationError(Exception error) {
    debugPrint('Initialization failed: $error');
    setState(() {
      _lastError = error;
      _showError = true;
    });

    // Auto-recovery attempt after delay
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showError = false);
      _initializeApp(); // Retry
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/bus_logo.png',
                  width: _logoSize,
                  height: _logoSize,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.directions_bus,
                    size: 120,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 30),
                // Progress indicator
                SizedBox(
                  width: _logoSize,
                  child: LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _loadingStatus,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Error overlay (if needed)
          if (_showError)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: AlertDialog(
                    title: Text('init_error_title'.tr()),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_lastError?.toString() ?? 'Unknown error'),
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 10),
                        const Text('Attempting to recover...'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => _initializeApp(),
                        child: const Text('Retry Now'),
                      ),
                      TextButton(
                        onPressed: () => _navigateBasedOnAuth(null),
                        child: const Text('Continue Anyway'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
