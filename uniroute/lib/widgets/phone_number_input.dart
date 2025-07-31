import 'package:flutter/material.dart';

class PhoneNumberInput extends StatefulWidget {
  final TextEditingController controller;

  const PhoneNumberInput({super.key, required this.controller});

  @override
  State<PhoneNumberInput> createState() => _PhoneNumberInputState();
}

class _PhoneNumberInputState extends State<PhoneNumberInput> {
  String selectedCountryCode = '+90'; // Default to Turkey
  String selectedFlag = 'flag_turkey.png';

  final List<Map<String, String>> countries = [
    {'name': 'Turkey', 'code': '+90', 'flag': 'flag_turkey.png'},
    {'name': 'Cyprus', 'code': '+357', 'flag': 'flag_cyprus.png'},
    {'name': 'Nigeria', 'code': '+234', 'flag': 'flag_nigeria.png'},
    {'name': 'USA', 'code': '+1', 'flag': 'flag_usa.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showCountryPicker(context),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/flags/$selectedFlag',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 6),
                Text(
                  selectedCountryCode,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType: TextInputType.number,
              maxLength: 10, // ✅ Limit to 10 digits
              decoration: const InputDecoration(
                counterText: '', // hides character counter
                border: InputBorder.none,
                hintText: '5335555555',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: countries.map((country) {
          return ListTile(
            leading: Image.asset(
              'assets/images/flags/${country['flag']}',
              width: 24,
              height: 24,
            ),
            title: Text(country['name']!),
            trailing: Text(country['code']!),
            onTap: () {
              setState(() {
                selectedCountryCode = country['code']!;
                selectedFlag = country['flag']!;
              });
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}
