import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() => runApp(const BusTrackerApp());

class BusTrackerApp extends StatelessWidget {
  const BusTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniBus Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Start with Schedule screen as active

  final List<Widget> _screens = [
    const MapScreen(),
    const StudentScheduleScreen(), // Your original reminder screen
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Map')),
      body: const Center(
        child: Text('Live bus map will be displayed here'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Text('User profile information'),
      ),
    );
  }
}

class Reminder {
  final String route;
  final List<String> departureTimes;
  final TimeOfDay notificationTime;
  final List<int> repeatDays;
  final DateTime? endDate;

  Reminder({
    required this.route,
    required this.departureTimes,
    required this.notificationTime,
    required this.repeatDays,
    required this.endDate,
  });
}

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({Key? key}) : super(key: key);

  @override
  StudentScheduleScreenState createState() => StudentScheduleScreenState();
}

class StudentScheduleScreenState extends State<StudentScheduleScreen> {
  String? _selectedRoute;
  List<String> _selectedDepartureTimes = [];
  TimeOfDay? _notificationTime;
  DateTime? _endDate;
  List<bool> _selectedDays = List.filled(7, false);
  final List<Reminder> _reminders = [];
  int? _editingIndex;

  final List<String> _routes = [
    'Lefkosa - Hamitköy',
    'Lefkosa - Honda',
    'Gönyeli',
    'Güzelyurt'
  ];

  final List<String> _departureTimes = [
    '11:45 AM',
    '12:45 PM',
    '1:45 PM',
    '3:45 PM',
    '5:30 PM'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Schedule Reminder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('ROUTE INFORMATION'),
            _buildDropdown(
              value: _selectedRoute,
              hint: 'Select a route',
              items: _routes,
              onChanged: (value) => setState(() => _selectedRoute = value),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('DEPARTURE TIME(S)'),
            ..._departureTimes.map((time) => _buildTimeOption(time)),
            const SizedBox(height: 24),
            if (_selectedRoute != null && _selectedDepartureTimes.isNotEmpty) ...[
              _buildSectionHeader('REMINDER SETTINGS'),
              _buildNotificationTimePicker(),
              const SizedBox(height: 16),
              _buildDaySelector(),
              const SizedBox(height: 16),
              _buildEndDateSelector(),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
            _buildSectionHeader('YOUR REMINDERS'),
            _buildReminderList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      hint: Text(hint),
      items: items.map((route) => DropdownMenuItem(
        value: route,
        child: Text(route),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTimeOption(String time) {
    final isSelected = _selectedDepartureTimes.contains(time);
    return ListTile(
      title: Text(time),
      leading: Checkbox(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedDepartureTimes.add(time);
            } else {
              _selectedDepartureTimes.remove(time);
            }
          });
        },
      ),
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDepartureTimes.remove(time);
          } else {
            _selectedDepartureTimes.add(time);
          }
        });
      },
    );
  }

  Widget _buildNotificationTimePicker() {
    return ListTile(
      title: const Text('Notification Time'),
      subtitle: Text(_notificationTime?.format(context) ?? 'Not set'),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _notificationTime ?? TimeOfDay.now(),
        );
        if (time != null) setState(() => _notificationTime = time);
      },
    );
  }

  Widget _buildDaySelector() {
    const dayAbbreviations = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Repeat on:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            return GestureDetector(
              onTap: () => setState(() => _selectedDays[index] = !_selectedDays[index]),
              child: CircleAvatar(
                backgroundColor: _selectedDays[index] ? Colors.blue : Colors.grey[200],
                child: Text(dayAbbreviations[index],
                    style: TextStyle(
                      color: _selectedDays[index] ? Colors.white : Colors.black)),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedDays.asMap().entries
              .where((e) => e.value)
              .map((e) => dayNames[e.key])
              .join(', '),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildEndDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Repeat until: ', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_endDate != null
                ? DateFormat('MMM d, y').format(_endDate!)
                : 'No end date'),
            const Spacer(),
            TextButton(
              child: Text(_endDate == null ? 'Set End Date' : 'Change'),
              onPressed: () => _selectEndDate(context),
            ),
            if (_endDate != null)
              TextButton(
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
                onPressed: () => setState(() => _endDate = null),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        child: Text(_editingIndex == null ? 'Save Reminder' : 'Update Reminder'),
        onPressed: () {
          if (_selectedRoute == null ||
              _selectedDepartureTimes.isEmpty ||
              _notificationTime == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please fill all required fields')));
            return;
          }

          final reminder = Reminder(
            route: _selectedRoute!,
            departureTimes: [..._selectedDepartureTimes],
            notificationTime: _notificationTime!,
            repeatDays: _selectedDays.asMap().entries.where((e) => e.value).map((e) => e.key).toList(),
            endDate: _endDate,
          );

          setState(() {
            if (_editingIndex == null) {
              _reminders.add(reminder);
            } else {
              _reminders[_editingIndex!] = reminder;
              _editingIndex = null;
            }
            _resetForm();
          });

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reminder saved successfully')));
        },
      ),
    );
  }

  void _resetForm() {
    _selectedRoute = null;
    _selectedDepartureTimes.clear();
    _notificationTime = null;
    _selectedDays = List.filled(7, false);
    _endDate = null;
  }

  Widget _buildReminderList() {
    if (_reminders.isEmpty) return const Text("No reminders yet.");

    return Column(
      children: _reminders.asMap().entries.map((entry) {
        final i = entry.key;
        final reminder = entry.value;
        final days = reminder.repeatDays
            .map((d) => ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d])
            .join(', ');
        final endDate = reminder.endDate != null
            ? DateFormat('MMM d, y').format(reminder.endDate!)
            : 'None';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.route,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.directions_bus, size: 16),
                  const SizedBox(width: 8),
                  Text('Departure(s): ${reminder.departureTimes.join(', ')}'),
                ]),
                Row(children: [
                  const Icon(Icons.notifications, size: 16),
                  const SizedBox(width: 8),
                  Text('Notify at: ${reminder.notificationTime.format(context)}'),
                ]),
                Row(children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text('Days: $days'),
                ]),
                Row(children: [
                  const Icon(Icons.event_available, size: 16),
                  const SizedBox(width: 8),
                  Text('Ends: $endDate'),
                ]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text('Edit'),
                      onPressed: () {
                        setState(() {
                          _selectedRoute = reminder.route;
                          _selectedDepartureTimes = [...reminder.departureTimes];
                          _notificationTime = reminder.notificationTime;
                          _selectedDays = List.generate(7,
                              (index) => reminder.repeatDays.contains(index));
                          _endDate = reminder.endDate;
                          _editingIndex = i;
                        });
                      },
                    ),
                    TextButton(
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        setState(() {
                          _reminders.removeAt(i);
                          if (_editingIndex == i) _editingIndex = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}