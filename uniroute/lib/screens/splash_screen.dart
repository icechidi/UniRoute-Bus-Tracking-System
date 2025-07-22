import 'dart:async';
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

  bool _showError = false;
  Exception? _lastError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final stopwatch = Stopwatch()..start();
    try {
      await _checkFirstLaunch();
      await _precacheResources();
      final user = await _checkAuthState();

      final remainingTime = _minSplashDuration - stopwatch.elapsed;
      if (remainingTime > Duration.zero) {
        await Future.delayed(remainingTime);
      }
      if (!mounted) return;
      _navigateBasedOnAuth(user);
    } catch (e) {
      if (!mounted) return;
      _handleInitializationError(e as Exception);
    } finally {
      stopwatch.stop();
    }
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;
    if (isFirstLaunch) {
      await prefs.setBool(_firstLaunchKey, false);
      await prefs.setString('language', 'en');
    }
  }

  Future<void> _precacheResources() async {
    await Future.wait([
      precacheImage(const AssetImage('assets/images/bus_logo.gif'), context),
    ]);
  }

  Future<User?> _checkAuthState() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final shouldKeepSignedIn = await AuthServices.shouldKeepSignedIn();
        if (shouldKeepSignedIn) {
          final storedToken = await AuthServices.getStoredToken();
          final storedEmail = await AuthServices.getStoredEmail();
          if (storedToken != null && storedEmail != null) {
            try {
              final credential =
                  GoogleAuthProvider.credential(idToken: storedToken);
              final userCredential =
                  await FirebaseAuth.instance.signInWithCredential(credential);
              user = userCredential.user;
              if (user?.email != storedEmail) {
                await FirebaseAuth.instance.signOut();
                user = null;
              }
            } catch (_) {}
          }
        }
      }
      return user;
    } catch (_) {
      return null;
    }
  }

  void _navigateBasedOnAuth(User? user) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: _transitionDuration,
        pageBuilder: (_, __, ___) {
          if (user != null) {
            return const SuccessScreen();
          } else {
            return const RoleSelectorScreen();
          }
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _handleInitializationError(Exception error) {
    setState(() {
      _lastError = error;
      _showError = true;
    });
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showError = false);
      _initializeApp();
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
                        onPressed: _initializeApp,
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
