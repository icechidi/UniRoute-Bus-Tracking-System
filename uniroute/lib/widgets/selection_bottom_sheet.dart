import 'package:flutter/material.dart';

/// A reusable bottom sheet widget that displays a list of selectable items.
/// When an item is tapped, it calls the [onSelected] callback.
class SelectionBottomSheet extends StatelessWidget {
  /// Title displayed at the top of the bottom sheet.
  final String title;

  /// List of items to be shown for selection.
  final List<String> items;

  /// Callback function that is triggered when an item is selected.
  final void Function(String) onSelected;

  /// Constructor for the bottom sheet.
  const SelectionBottomSheet({
    super.key,
    required this.title,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding around the entire sheet content
      padding: const EdgeInsets.all(16),

      // Styling the bottom sheet: white background with rounded top corners
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      // Main content of the bottom sheet
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content height
        children: [
          // Header row with title and close button
          Row(
            children: [
              // Title on the left, expands to fill available space
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Close icon on the right that dismisses the bottom sheet
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close),
              ),
            ],
          ),

          // Divider between header and list
          const Divider(),

          // Scrollable list of selectable items
          ListView.separated(
            shrinkWrap: true, // Make list take only needed space
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(), // Divider between items
            itemBuilder: (_, index) => ListTile(
              title: Text(items[index]),

              // When tapped, call the onSelected callback with selected item
              onTap: () => onSelected(items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

