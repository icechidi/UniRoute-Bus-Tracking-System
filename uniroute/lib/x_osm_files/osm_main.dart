import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'North Cyprus Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}


//dependencies:
  // flutter:
  //   sdk: flutter
  // flutter_map: ^6.1.0
  // latlong2: ^0.9.0
  // geolocator: ^11.0.0
  // http: ^1.2.1
