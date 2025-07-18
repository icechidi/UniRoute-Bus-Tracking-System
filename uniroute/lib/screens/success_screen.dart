import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessScreen extends StatefulWidget {
  final String? title;
  final String? message;

  const SuccessScreen({super.key, this.title, this.message});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/success.json',
              repeat: false,
              width: 200,
              height: 200,
              onLoaded: (composition) {
                Future.delayed(composition.duration, () {
                  if (!mounted) return;
                  Navigator.of(context).pushReplacementNamed('/home');
                });
              },
            ),
            if (widget.title != null) ...[
              const SizedBox(height: 24),
              Text(
                widget.title!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (widget.message != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
