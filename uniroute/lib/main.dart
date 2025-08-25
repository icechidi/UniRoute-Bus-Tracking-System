import 'package:flutter/material.dart';
import 'routes.dart'; // ✅ Import the route definitions

void main() => runApp(const BusApp());

class BusApp extends StatelessWidget {
  const BusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.map, // ✅ Use centralized constant
      onGenerateRoute: AppRoutes.generateRoute, // ✅ Route generator
    );
  }

}