import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';

class DashboardPage extends StatefulWidget {
  final HiveSession session;

  DashboardPage({super.key, required this.session});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> ticketStats = [
    {"status": "Pending", "count": 5, "color": Colors.orange},
    {"status": "Open", "count": 12, "color": Colors.blue},
    {"status": "In Progress", "count": 7, "color": Colors.green},
    {"status": "Postponed", "count": 3, "color": Colors.purple}
  ];

  final List<Map<String, String>> recentTickets = List.generate(8, (index) {
    return {
      "title": "Ticket #${index + 1}",
      "status": ["Open", "Closed", "Pending", "In Progress"][index % 4],
      "date": "2025-03-20"
    };
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double maxWidth = 1200; // Prevents stretching on ultra-wide screens

    int columns = 4; // Default for large screens
    if (screenWidth < 1100) columns = 3;
    if (screenWidth < 900) columns = 2;
    if (screenWidth < 600) columns = 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth), // Fixes desktop stretching
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **Scrollable Content**
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ticket Overview
                          Text("Ticket Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),

                          // **Stats Grid (Responsive)**
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return GridView.builder(
                                shrinkWrap: true, // Prevents infinite height issue
                                physics: NeverScrollableScrollPhysics(), // Prevents nested scroll conflicts
                                itemCount: ticketStats.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 2.5,
                                ),
                                itemBuilder: (context, index) {
                                  return Card(
                                    elevation: 2,
                                    color: ticketStats[index]["color"].withOpacity(0.2),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: ticketStats[index]["color"],
                                            child: Text(ticketStats[index]["count"].toString(),
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                          SizedBox(height: 5),
                                          Text(ticketStats[index]["status"], style: TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          SizedBox(height: 20),

                          // **Recent Tickets**
                          Text("Recent Tickets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: recentTickets.length,
                            itemBuilder: (context, index) {
                              return Card(
                                child: ListTile(
                                  leading: Icon(Icons.confirmation_number, color: Colors.blue),
                                  title: Text(recentTickets[index]["title"]!),
                                  subtitle: Text("Status: ${recentTickets[index]["status"]!}"),
                                  trailing: Text(recentTickets[index]["date"]!, style: TextStyle(color: Colors.grey)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
