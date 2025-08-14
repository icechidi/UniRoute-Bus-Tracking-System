import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Route 1 Schedule - Based on your map route
  final List<Map<String, dynamic>> route1Schedule = [
    {
      "time": "06:00 AM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Medical Center",
        "Shopping Mall",
        "Business District",
        "Central Park",
        "Government Complex",
        "Airport Terminal",
        "Industrial Zone",
        "Residential Area A",
        "Residential Area B",
        "Sports Complex",
        "Hospital",
        "Train Station",
        "Old Town",
        "Market Square",
        "Cultural Center",
        "Tech Park",
        "Marina",
        "City Hall",
        "Financial District",
        "Convention Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "07:30 AM",
      "status": "active",
      "stops": [
        "University Campus (Start)",
        "Medical Center",
        "Shopping Mall",
        "Business District",
        "Central Park",
        "Government Complex",
        "Airport Terminal",
        "Industrial Zone",
        "Residential Area A",
        "Residential Area B",
        "Sports Complex",
        "Hospital",
        "Train Station",
        "Old Town",
        "Market Square",
        "Cultural Center",
        "Tech Park",
        "Marina",
        "City Hall",
        "Financial District",
        "Convention Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "09:00 AM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Medical Center",
        "Shopping Mall",
        "Business District",
        "Central Park",
        "Government Complex",
        "Airport Terminal",
        "Industrial Zone",
        "Residential Area A",
        "Residential Area B",
        "Sports Complex",
        "Hospital",
        "Train Station",
        "Old Town",
        "Market Square",
        "Cultural Center",
        "Tech Park",
        "Marina",
        "City Hall",
        "Financial District",
        "Convention Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "10:30 AM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Medical Center",
        "Shopping Mall",
        "Business District",
        "Central Park",
        "Government Complex",
        "Airport Terminal",
        "Industrial Zone",
        "Residential Area A",
        "Residential Area B",
        "Sports Complex",
        "Hospital",
        "Train Station",
        "Old Town",
        "Market Square",
        "Cultural Center",
        "Tech Park",
        "Marina",
        "City Hall",
        "Financial District",
        "Convention Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "12:00 PM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Medical Center",
        "Shopping Mall",
        "Business District",
        "Central Park",
        "Government Complex",
        "Airport Terminal",
        "Industrial Zone",
        "Residential Area A",
        "Residential Area B",
        "Sports Complex",
        "Hospital",
        "Train Station",
        "Old Town",
        "Market Square",
        "Cultural Center",
        "Tech Park",
        "Marina",
        "City Hall",
        "Financial District",
        "Convention Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "01:30 PM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Medical Center",
        "Shopping Mall",
        "Business District",
        "Central Park",
        "Government Complex",
        "Airport Terminal",
        "Industrial Zone",
        "Residential Area A",
        "Residential Area B",
        "Sports Complex",
        "Hospital",
        "Train Station",
        "Old Town",
        "Market Square",
        "Cultural Center",
        "Tech Park",
        "Marina",
        "City Hall",
        "Financial District",
        "Convention Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "03:00 PM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Medical Center",
        "Shopping Mall",
        "Business District",
        "Central Park",
        "Government Complex",
        "Airport Terminal",
        "Industrial Zone",
        "Residential Area A",
        "Residential Area B",
        "Sports Complex",
        "Hospital",
        "Train Station",
        "Old Town",
        "Market Square",
        "Cultural Center",
        "Tech Park",
        "Marina",
        "City Hall",
        "Financial District",
        "Convention Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "04:30 PM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Medical Center",
        "Shopping Mall",
        "Business District",
        "Central Park",
        "Government Complex",
        "Airport Terminal",
        "Industrial Zone",
        "Residential Area A",
        "Residential Area B",
        "Sports Complex",
        "Hospital",
        "Train Station",
        "Old Town",
        "Market Square",
        "Cultural Center",
        "Tech Park",
        "Marina",
        "City Hall",
        "Financial District",
        "Convention Center",
        "University Campus (End)"
      ]
    },
  ];

  // Return Route Schedule
  final List<Map<String, dynamic>> returnRouteSchedule = [
    {
      "time": "06:30 AM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Convention Center",
        "Financial District",
        "City Hall",
        "Marina",
        "Tech Park",
        "Cultural Center",
        "Market Square",
        "Old Town",
        "Train Station",
        "Hospital",
        "Sports Complex",
        "Residential Area B",
        "Residential Area A",
        "Industrial Zone",
        "Airport Terminal",
        "Government Complex",
        "Central Park",
        "Business District",
        "Shopping Mall",
        "Medical Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "08:00 AM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Convention Center",
        "Financial District",
        "City Hall",
        "Marina",
        "Tech Park",
        "Cultural Center",
        "Market Square",
        "Old Town",
        "Train Station",
        "Hospital",
        "Sports Complex",
        "Residential Area B",
        "Residential Area A",
        "Industrial Zone",
        "Airport Terminal",
        "Government Complex",
        "Central Park",
        "Business District",
        "Shopping Mall",
        "Medical Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "09:30 AM",
      "status": "active",
      "stops": [
        "University Campus (Start)",
        "Convention Center",
        "Financial District",
        "City Hall",
        "Marina",
        "Tech Park",
        "Cultural Center",
        "Market Square",
        "Old Town",
        "Train Station",
        "Hospital",
        "Sports Complex",
        "Residential Area B",
        "Residential Area A",
        "Industrial Zone",
        "Airport Terminal",
        "Government Complex",
        "Central Park",
        "Business District",
        "Shopping Mall",
        "Medical Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "11:00 AM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Convention Center",
        "Financial District",
        "City Hall",
        "Marina",
        "Tech Park",
        "Cultural Center",
        "Market Square",
        "Old Town",
        "Train Station",
        "Hospital",
        "Sports Complex",
        "Residential Area B",
        "Residential Area A",
        "Industrial Zone",
        "Airport Terminal",
        "Government Complex",
        "Central Park",
        "Business District",
        "Shopping Mall",
        "Medical Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "12:30 PM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Convention Center",
        "Financial District",
        "City Hall",
        "Marina",
        "Tech Park",
        "Cultural Center",
        "Market Square",
        "Old Town",
        "Train Station",
        "Hospital",
        "Sports Complex",
        "Residential Area B",
        "Residential Area A",
        "Industrial Zone",
        "Airport Terminal",
        "Government Complex",
        "Central Park",
        "Business District",
        "Shopping Mall",
        "Medical Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "02:00 PM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Convention Center",
        "Financial District",
        "City Hall",
        "Marina",
        "Tech Park",
        "Cultural Center",
        "Market Square",
        "Old Town",
        "Train Station",
        "Hospital",
        "Sports Complex",
        "Residential Area B",
        "Residential Area A",
        "Industrial Zone",
        "Airport Terminal",
        "Government Complex",
        "Central Park",
        "Business District",
        "Shopping Mall",
        "Medical Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "03:30 PM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Convention Center",
        "Financial District",
        "City Hall",
        "Marina",
        "Tech Park",
        "Cultural Center",
        "Market Square",
        "Old Town",
        "Train Station",
        "Hospital",
        "Sports Complex",
        "Residential Area B",
        "Residential Area A",
        "Industrial Zone",
        "Airport Terminal",
        "Government Complex",
        "Central Park",
        "Business District",
        "Shopping Mall",
        "Medical Center",
        "University Campus (End)"
      ]
    },
    {
      "time": "05:00 PM",
      "status": "upcoming",
      "stops": [
        "University Campus (Start)",
        "Convention Center",
        "Financial District",
        "City Hall",
        "Marina",
        "Tech Park",
        "Cultural Center",
        "Market Square",
        "Old Town",
        "Train Station",
        "Hospital",
        "Sports Complex",
        "Residential Area B",
        "Residential Area A",
        "Industrial Zone",
        "Airport Terminal",
        "Government Complex",
        "Central Park",
        "Business District",
        "Shopping Mall",
        "Medical Center",
        "University Campus (End)"
      ]
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.directions_bus;
      case 'upcoming':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.schedule;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'upcoming':
        return 'Scheduled';
      case 'completed':
        return 'Completed';
      default:
        return 'Scheduled';
    }
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule, int index) {
    final status = schedule['status'] as String;
    final time = schedule['time'] as String;
    final stops = schedule['stops'] as List<String>;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          (index * 0.1) + 0.3,
          curve: Curves.easeOutBack,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.08 * 255).round()),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: status == 'active'
              ? Border.all(color: Colors.green, width: 2)
              : null,
        ),
        child: ExpansionTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 28,
            ),
          ),
          title: Row(
            children: [
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              if (status == 'active')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'LIVE',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            '${_getStatusText(status)} • ${stops.length} stops',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            Icons.expand_more,
            color: _getStatusColor(status),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Stops:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...stops.asMap().entries.map((entry) {
                    final stopIndex = entry.key;
                    final stop = entry.value;
                    final isFirst = stopIndex == 0;
                    final isLast = stopIndex == stops.length - 1;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isFirst
                                  ? Colors.green
                                  : isLast
                                      ? Colors.red
                                      : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${stopIndex + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              stop,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isFirst || isLast
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isFirst || isLast
                                    ? Colors.black87
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                          if (isFirst)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'START',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (isLast)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'END',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Bus Schedule',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.arrow_forward),
                        text: 'Outbound',
                      ),
                      Tab(
                        icon: Icon(Icons.arrow_back),
                        text: 'Return',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Outbound Route
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: route1Schedule.length,
                    itemBuilder: (context, index) {
                      return _buildScheduleCard(route1Schedule[index], index);
                    },
                  ),
                  // Return Route
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: returnRouteSchedule.length,
                    itemBuilder: (context, index) {
                      return _buildScheduleCard(
                          returnRouteSchedule[index], index);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
