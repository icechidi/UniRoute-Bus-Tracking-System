import 'package:flutter/material.dart';

class RouteSelector extends StatelessWidget {
  final String? selectedRoute;
  final Function(String) onSelect;

  const RouteSelector({
    Key? key,
    this.selectedRoute,
    required this.onSelect,
  }) : super(key: key);

  final List<String> routes = const [
    'Gonyeli - Yenikent',
    'Lefkosa - Honda',
    'Lefkosa - Hamitkoy',
    'Lefkosa - Hastane',
    'Guzelyurt',
    'Girne',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Styled ROUTE header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'ROUTE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: routes.map((route) {
            final bool isSelected = route == selectedRoute;
            return GestureDetector(
              onTap: () => onSelect(route),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  route,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
