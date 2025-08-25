import 'package:flutter/material.dart';

class TimeSelector extends StatelessWidget {
  final String? selectedTime;
  final Function(String) onSelect;

  const TimeSelector({super.key, this.selectedTime, required this.onSelect});

  final List<String> times = const [
    '07:45', '08:45', '12:00', '13:00', '14:00', '16:00', '17:45'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time header with blue rounded container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'TIME',
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
          children: times.map((time) {
            final bool isSelected = time == selectedTime;
            return GestureDetector(
              onTap: () => onSelect(time),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  time,
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
