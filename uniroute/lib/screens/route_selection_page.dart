import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ Add this import
import '../widgets/emergency_button.dart';
import '../widgets/universal_app_bar.dart';

class RouteSelectionPage extends StatefulWidget {
  final void Function(String route, String time) onContinue;
  final VoidCallback onProfileTap; // ✅ Add this

  const RouteSelectionPage({
    super.key,
    required this.onContinue,
    required this.onProfileTap, // ✅ Add this
  });

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
      backgroundColor: Colors.white,
      appBar: UniversalAppBar(
        title: 'Transports',
        onProfileTap: widget.onProfileTap, // ✅ Pass tap handler
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                children: [
                  _buildSectionTitle('ROUTE'),
                  _buildChoiceChips(routes, selectedRoute, (val) {
                    setState(() => selectedRoute = val);
                  }),
                  const SizedBox(height: 32),
                  const Divider(thickness: 1, height: 40, color: Colors.grey),
                  _buildSectionTitle('TIME'),
                  _buildChoiceChips(times, selectedTime, (val) {
                    setState(() => selectedTime = val);
                  }),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: ElevatedButton(
                      onPressed: selectedRoute.isNotEmpty &&
                              selectedTime.isNotEmpty
                          ? () => widget.onContinue(selectedRoute, selectedTime)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.black,
                        disabledForegroundColor: Colors.white70,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.poppins(
                          // ✅ Changed to Poppins
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const EmergencyButton(bottomSpacing: 0),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 100, 174),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              // ✅ Changed to Poppins
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChips(
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: options.map((option) {
        final bool isSelected = option == selected;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            width: 90,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[900] : Colors.black,
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25), // Shadow color
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              option,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                // ✅ Changed to Poppins
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
