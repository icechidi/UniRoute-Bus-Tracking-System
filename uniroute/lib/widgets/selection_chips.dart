import 'package:flutter/material.dart';

/// A stateless widget that displays a list of selectable chips (pills).
/// Each chip represents a string item and can be selected by tapping.
class SelectionChips extends StatelessWidget {
  /// List of string items to be displayed as chips.
  final List<String> items;

  /// The index of the currently selected chip. Can be null (no selection).
  final int? selectedIndex;

  /// Callback function called when a chip is tapped, with the selected index.
  final void Function(int) onSelected;

  /// Constructor to initialize the SelectionChips widget.
  const SelectionChips({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12, // Horizontal spacing between chips
      runSpacing: 12, // Vertical spacing when chips wrap to a new line

      // Create a list of chip widgets dynamically based on the items list
      children: List.generate(items.length, (index) {
        // Check if the current chip is selected
        final isSelected = selectedIndex == index;

        return GestureDetector(
          // When tapped, call the onSelected callback with the chip's index
          onTap: () => onSelected(index),
          child: Container(
            // Padding inside each chip
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            
            // Styling of the chip container
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.transparent, // Black background if selected
              borderRadius: BorderRadius.circular(24), // Rounded edges for pill shape
              border: Border.all(color: Colors.black), // Black border
            ),

            // Text label of the chip
            child: Text(
              items[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black, // White text if selected
              ),
            ),
          ),
        );
      }),
    );
  }
}
