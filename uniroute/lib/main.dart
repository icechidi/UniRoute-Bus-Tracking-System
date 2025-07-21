import 'package:flutter/material.dart';
import 'package:uniroute/screens/schedule_screen.dart'; // Import the ScheduleScreen widget
import 'routes.dart'; // Import route definitions and route generator

/// Entry point of the application.
/// Starts the BusApp widget.
void main() => runApp(const BusApp());

/// Root widget of the Bus application.
/// Uses MaterialApp with custom routing configuration.
class BusApp extends StatelessWidget {
  const BusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus App', // App title used by the OS
      debugShowCheckedModeBanner: false, // Hide debug banner in UI
      onGenerateRoute: AppRoutes.generateRoute, // Delegate route generation to AppRoutes
      initialRoute: '/', // Starting route of the app
    );
  }
}

/// Alternative root widget named MyApp.
/// Sets a theme and home screen directly without routing.
///
/// Note: This widget is defined but not used in the current app.
/// The app uses BusApp as the root widget instead.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schedule App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue), // Sets primary color theme
      home: const ScheduleScreen(), // Directly sets ScheduleScreen as the home screen
    );
  }   
}
