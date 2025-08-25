import 'package:flutter/material.dart';
import '../widgets/weekly_schedule_widget.dart';

class WeeklyScheduleScreen extends StatelessWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WeeklyScheduleWidget(),
      ),
    );
  }
}
