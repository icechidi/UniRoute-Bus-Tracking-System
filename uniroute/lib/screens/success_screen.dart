import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/animations/success.json',
          repeat: false,
          width: 200,
          height: 200,
          onLoaded: (composition) {
            Future.delayed(composition.duration, () {
              Navigator.pushReplacementNamed(context, '/home');
            });
          },
        ),
      ),
    );
  }
}
