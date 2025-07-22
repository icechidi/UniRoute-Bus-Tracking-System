import 'package:flutter/material.dart';
import 'pre_trip_page.dart';
import '../widgets/emergency_button.dart';
import 'main_screen.dart';

class RouteSelectionPage extends StatefulWidget {
  const RouteSelectionPage({super.key});

  @override
  State<RouteSelectionPage> createState() => _RouteSelectionPageState();
}

class _RouteSelectionPageState extends State<RouteSelectionPage> {
  String selectedRoute = '';
  String selectedTime = '';

  final List<String> routes = [
    "Gonyeli - Yenikent",
    "Lefkoşa - Honda",
    "Lefkoşa - Hamitköy",
    "Lefkoşa - Hastane",
    "Güzelyurt",
    "Girne",
  ];

  final List<String> times = [
    "07:45",
    "09:45",
    "12:00",
    "13:00",
    "14:00",
    "16:00",
    "17:45",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transports'), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildSectionTitle('ROUTE'),
          _buildChoiceChips(routes, selectedRoute, (val) {
            setState(() {
              selectedRoute = val;
            });
          }),
          const SizedBox(height: 10),
          _buildSectionTitle('TIME'),
          _buildChoiceChips(times, selectedTime, (val) {
            setState(() {
              selectedTime = val;
            });
          }),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              onPressed: selectedRoute.isNotEmpty && selectedTime.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PreTripPage(
                            route: selectedRoute,
                            time: selectedTime,
                            busId: 'ID #4571',
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Continue'),
            ),
          ),
          const Spacer(),
          const EmergencyButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildChoiceChips(
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: options.map((option) {
          final bool isSelected = option == selected;
          return ChoiceChip(
            label: Text(option),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            selectedColor: Colors.blue,
            backgroundColor: Colors.grey[200],
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
          );
        }).toList(),
      ),
    );
  }
}
