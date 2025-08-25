import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/booking_screen.dart'; // ✅ New import
import 'screens/schedule_screen.dart';
import 'screens/weekly_schedule_screen.dart';

/// Defines route names as constants to avoid typos and ease management.
class Routes {
  static const String home = '/';
  static const String map = '/map';
  static const String schedule = '/schedule';
  static const String profile = '/profile';
  static const String booking = '/booking';       // ✅ New route
  static const String weekly = '/weekly';         // ✅ New route
}

/// Placeholder for WeeklyScreen
class WeeklyScreen extends StatelessWidget {
  const WeeklyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Weekly Screen (Coming Soon)'),
      ),
    );
  }
}

/// Centralized route generator
class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case Routes.map:
        return MaterialPageRoute(builder: (_) => const MapScreen());

      case Routes.schedule:
        return MaterialPageRoute(builder: (_) => const ScheduleScreen());

      case Routes.profile:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("User Profile")),
            body: const Center(child: Text("User Profile Details Here")),
          ),
        );

      case Routes.booking:
        return MaterialPageRoute(builder: (_) => const BookingScreen());

      case Routes.weekly:
        return MaterialPageRoute(builder: (_) => const WeeklyScheduleScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("No route defined")),
          ),
        );
    }
  }
}
