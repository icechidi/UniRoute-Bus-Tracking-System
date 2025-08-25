import 'package:flutter/material.dart';

class ReminderSelector extends StatefulWidget {
  final Function(int) onHourChanged;
  final Function(int) onMinuteChanged;

  const ReminderSelector({
    super.key,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  @override
  State<ReminderSelector> createState() => _ReminderSelectorState();
}

class _ReminderSelectorState extends State<ReminderSelector> {
  final FixedExtentScrollController hourController = FixedExtentScrollController();
  final FixedExtentScrollController minuteController = FixedExtentScrollController();

  int selectedHour = 0;
  int selectedMinute = 0;

  List<int> get hours => List<int>.generate(24, (index) => index);
  List<int> get minutes => List<int>.generate(60, (index) => index);

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  Widget _buildNumberPicker({
    required List<int> values,
    required FixedExtentScrollController controller,
    required Function(int) onSelectedItemChanged,
    required int selectedValue,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 👇 Label above each picker
          Text(
            values.length == 24 ? 'Hour' : 'Minute',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: 40,
              diameterRatio: 1.1,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: onSelectedItemChanged,
              overAndUnderCenterOpacity: 0.4,
              perspective: 0.002,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: values.length,
                builder: (context, index) {
                  final value = values[index];
                  final isSelected = value == selectedValue;
                  return Center(
                    child: Text(
                      value.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberPicker(
              values: hours,
              controller: hourController,
              onSelectedItemChanged: (value) {
                setState(() => selectedHour = value);
                widget.onHourChanged(value);
              },
              selectedValue: selectedHour,
            ),
            const SizedBox(width: 16),
            _buildNumberPicker(
              values: minutes,
              controller: minuteController,
              onSelectedItemChanged: (value) {
                setState(() => selectedMinute = value);
                widget.onMinuteChanged(value);
              },
              selectedValue: selectedMinute,
            ),
          ],
        ),
      ],
    );
  }
}
