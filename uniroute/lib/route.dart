import 'package:flutter/material.dart';
import 'main.dart';
import 'schedule.dart';
import 'weekly_schedule.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const MapScreen());
      case '/schedule':
        return MaterialPageRoute(builder: (_) => const ScheduleScreen());
      case 'weeklySchedule':
        return MaterialPageRoute(builder:  (_) => const WeeklyScheduleScreen());
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text("User Profile")),
            body: Center(child: Text("User Profile Details Here")),
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
