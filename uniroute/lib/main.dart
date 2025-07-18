import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool initializationError = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await EasyLocalization.ensureInitialized();
  } catch (e) {
    debugPrint("Initialization failed: $e");
    initializationError = true;
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('tr')],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      child: MyApp(initializationError: initializationError),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool initializationError;

  const MyApp({super.key, required this.initializationError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniRoute',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: initializationError
          ? _InitializationErrorScreen()
          : const SplashScreen(),
    );
  }
}

class _InitializationErrorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text('initialization_error'.tr()),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => main(),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
