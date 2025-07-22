import 'package:flutter/material.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({Key? key}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  Map<String, List<Map<String, String>>> weeklyBookings = {
    "MONDAY": [],
    "TUESDAY": [],
    "WEDNESDAY": [],
    "THURSDAY": [],
    "FRIDAY": [],
  };

  final List<String> addressOptions = [
    "Adamar Market",
    "Durumcu Baba - Gonyeli",
    "Yalcin Park - Gonyeli",
    "The Hane - Gonyeli",
    "Big Kiler Market - Gonyeli",
    "Gonyeli Municipality - Yenikent",
    "Molto Market -China Bazaar - Ortakoy",
  ];

  final List<String> timeOptions = [
    "7:45",
    "9:45",
    "11:45",
    "12:45",
    "13:45",
    "15:45",
    "17:30",
  ];

  Set<Map<String, String>> deleteModeSet = {};

  // Show bottom sheet to select an address
  void _showAddAddressDialog(String day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(), // Close on tap outside
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GestureDetector(
                onTap: () {}, // Prevent tap from closing sheet if inside content
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Your Address',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: addressOptions.length,
                        itemBuilder: (context, index) {
                          final addr = addressOptions[index];
                          return ListTile(
                            title: Text(addr),
                            onTap: () {
                              Navigator.of(context).pop();
                              _showTimePicker(day, addr);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Show bottom sheet to select a time for a selected address
  void _showTimePicker(String day, String route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(), // Close on tap outside
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GestureDetector(
                onTap: () {}, // Prevent tap from closing sheet if inside content
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Your Time',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: timeOptions.length,
                        itemBuilder: (context, index) {
                          final selectedTime = timeOptions[index];
                          return ListTile(
                            title: Text(selectedTime),
                            onTap: () {
                              Navigator.of(context).pop();
                              setState(() {
                                weeklyBookings[day]?.add({"route": route, "time": selectedTime});
                                weeklyBookings[day]?.sort((a, b) => a["time"]!.compareTo(b["time"]!));
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = weeklyBookings.keys.toList();

    return GestureDetector(
      onTap: () {
        // Clear expanded items if tap is outside
        setState(() {
          deleteModeSet.clear();
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          centerTitle: true,
          title: const Text(
            "Weekly",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: days.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Booking",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      )
                    ],
                  ),
                ),
              );
            }

            final day = days[index - 1];
            final bookings = weeklyBookings[day]!;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      day,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87),
                    ),
                  ),
                  Expanded(
                    child: bookings.isEmpty
                        ? Text(
                      "Address area, Time",
                      style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontStyle: FontStyle.italic),
                    )
                        : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: bookings.map((booking) {
                        final isExpanded = deleteModeSet.contains(booking);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                deleteModeSet.remove(booking);
                              } else {
                                deleteModeSet.clear();
                                deleteModeSet.add(booking);
                              }
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.calendar_month,
                                  size: 24,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (isExpanded)
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 120,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            booking['route'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            booking['time'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: -12,
                                      right: -12,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            bookings.remove(booking);
                                            deleteModeSet.remove(booking);
                                          });
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: const Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: GestureDetector(
                      onTap: () => _showAddAddressDialog(day),
                      child: Text(
                        "+",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
          ],
        ),
        bottomSheet: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Saved successfully")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              "Save",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
