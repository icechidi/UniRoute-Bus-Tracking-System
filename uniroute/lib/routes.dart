import 'package:flutter/material.dart';
import 'screens/map_screen.dart'; // Import MapScreen widget
import 'screens/schedule_screen.dart'; // Import ScheduleScreen widget
import 'screens/weekly_schedule_screen.dart'; // Import WeeklyScheduleScreen widget

/// Defines route names as constants to avoid typos and ease management.
class Routes {
  static const String home = '/';                // Home route (main screen)
  static const String schedule = '/schedule';    // Schedule screen route
  static const String weeklySchedule = '/weeklySchedule'; // Weekly schedule screen route
  static const String profile = '/profile';      // Profile screen route
}

/// Centralized route generator that returns appropriate pages
/// based on the requested route name.
class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
        // If route is '/', load MapScreen widget
        return MaterialPageRoute(builder: (_) => const MapScreen());

      case Routes.schedule:
        // If route is '/schedule', load ScheduleScreen widget
        return MaterialPageRoute(builder: (_) => const ScheduleScreen());

      case Routes.weeklySchedule:
        // If route is '/weeklySchedule', load WeeklyScheduleScreen widget
        return MaterialPageRoute(builder: (_) => const WeeklyScheduleScreen());

      case Routes.profile:
        // If route is '/profile', display a simple profile page scaffold
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("User Profile")),
            body: const Center(child: Text("User Profile Details Here")),
          ),
        );

      default:
        // If route name is unrecognized, show a fallback screen
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("No route defined")),
          ),
        );
    }
  }
}
