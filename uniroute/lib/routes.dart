import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/weekly_schedule_screen.dart';
import 'screens/map_screen.dart'; // ✅ Add this for completeness

/// Defines route names as constants to avoid typos and ease management.
class Routes {
  static const String home = '/';
  static const String map = '/map';                      // ✅ Added
  static const String schedule = '/schedule';
  static const String weeklySchedule = '/weeklySchedule';
  static const String profile = '/profile';
}

/// Centralized route generator
class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case Routes.map:
        return MaterialPageRoute(builder: (_) => const MapScreen()); // ✅ Added

      case Routes.schedule:
        return MaterialPageRoute(builder: (_) => const ScheduleScreen());

      case Routes.weeklySchedule:
        return MaterialPageRoute(builder: (_) => const WeeklyScheduleScreen());

      case Routes.profile:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("User Profile")),
            body: const Center(child: Text("User Profile Details Here")),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("No route defined")),
          ),
        );
    }
  }
}

