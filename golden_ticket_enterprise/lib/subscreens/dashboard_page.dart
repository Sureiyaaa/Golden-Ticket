import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  final HiveSession session;

  const DashboardPage({super.key, required this.session});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ScrollController _scrollController = ScrollController();

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
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Consumer<DataManager>(
                builder: (context, dataManager, _) {
                  // ✅ Get Tickets from DataManager
                  List<Ticket> tickets = dataManager.tickets;

                  // ✅ Count tickets per category
                  Map<String, int> ticketCounts = {
                    "Pending": tickets.where((t) => t.status == "Pending").length,
                    "Open": tickets.where((t) => t.status == "Open").length,
                    "In Progress": tickets.where((t) => t.status == "In Progress").length,
                    "Postponed": tickets.where((t) => t.status == "Postponed").length,
                  };

                  // ✅ Ticket Status Colors
                  Map<String, Color> statusColors = {
                    "Pending": Colors.orange,
                    "Open": Colors.blue,
                    "In Progress": Colors.green,
                    "Postponed": Colors.purple,
                  };

                  // ✅ Recent Tickets (Last 10)
                  List<Ticket> recentTickets = tickets.take(10).toList();

                  return Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // **Ticket Overview**
                          Text("Ticket Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),

                          // **Stats Grid (Responsive)**
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: ticketCounts.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 2.5,
                                ),
                                itemBuilder: (context, index) {
                                  String status = ticketCounts.keys.elementAt(index);
                                  int count = ticketCounts[status] ?? 0;
                                  Color color = statusColors[status] ?? Colors.grey;

                                  return Card(
                                    elevation: 2,
                                    color: color.withOpacity(0.2),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: color,
                                            child: Text("$count",
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                          SizedBox(height: 5),
                                          Text(status, style: TextStyle(fontSize: 14)),
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

                          recentTickets.isEmpty
                              ? Center(child: Text("No recent tickets"))
                              : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: recentTickets.length,
                            itemBuilder: (context, index) {
                              Ticket ticket = recentTickets[index];
                              return Card(
                                child: ListTile(
                                  leading: Icon(Icons.confirmation_number, color: Colors.blue),
                                  title: Text("#${ticket.ticketID}: ${ticket.ticketTitle ?? "No title provided"}"),
                                  subtitle: Row(
                                    children: [
                                      Chip(
                                        label: Text(ticket.status,
                                            style: TextStyle(color: Colors.white, fontSize: 12)),
                                        backgroundColor: statusColors[ticket.status] ?? Colors.grey,
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        TimeUtil.formatTimestamp(ticket.createdAt), // Show only date
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
