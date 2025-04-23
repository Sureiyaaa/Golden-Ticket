import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:provider/provider.dart';

class FeedbackReportTab extends StatefulWidget {
  final HiveSession session;

  const FeedbackReportTab({super.key, required this.session});

  @override
  State<FeedbackReportTab> createState() => _FeedbackReportTabState();
}

class _FeedbackReportTabState extends State<FeedbackReportTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        final allStaff = dataManager.getStaff();
        final isMobile = MediaQuery.of(context).size.width < 600;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Staff Feedback Report'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isMobile
                ? ListView.builder(
              itemCount: allStaff.length,
              itemBuilder: (context, index) {
                final staff = allStaff[index];
                final ratings = dataManager.ratings.where(
                      (r) => r.chatroom.ticket?.assigned?.userID == staff.userID,
                ).toList();

                final averageRating = ratings.isNotEmpty
                    ? ratings.map((r) => r.score).reduce((a, b) => a + b) / ratings.length
                    : null;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      child: Text(staff.firstName[0]),
                    ),
                    title: Text('${staff.firstName} ${staff.lastName}'),
                    subtitle: Text(
                      "Average Rating: ${averageRating?.toStringAsFixed(2) ?? 'N/A'}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: () {
                        showRelatedTicketsDialog(context, dataManager, staff);
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text("View Tickets"),
                    ),
                  ),
                );
              },
            ) : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
              child: DataTable(
                columnSpacing: 40,
                headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade200),
                columns: const [
                  DataColumn(
                    label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text("Average Rating", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
                rows: allStaff.map((staff) {
                  final ratings = dataManager.ratings.where(
                        (r) => r.chatroom.ticket?.assigned?.userID == staff.userID,
                  ).toList();

                  final averageRating = ratings.isNotEmpty
                      ? ratings.map((r) => r.score).reduce((a, b) => a + b) / ratings.length
                      : null;

                  return DataRow(
                    cells: [
                      DataCell(Text('${staff.firstName} ${staff.lastName}')),
                      DataCell(Text(
                        averageRating?.toStringAsFixed(2) ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      )),
                      DataCell(
                        ElevatedButton.icon(
                          onPressed: () {
                            showRelatedTicketsDialog(context, dataManager, staff);
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text("View Tickets"),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}

void showRelatedTicketsDialog(BuildContext context, DataManager dataManager, User user) {
  final chatrooms = dataManager.chatrooms.where((chat) => chat.ticket?.assigned?.userID == user.userID).toList();
  final ratings = dataManager.ratings;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Tickets by ${user.firstName} ${user.lastName}'),
        content: chatrooms.isNotEmpty
            ? SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: chatrooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final chat = chatrooms[index];
              final rating = ratings.where((r) => r.chatroom.chatroomID == chat.chatroomID).firstOrNull;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(chat.ticket?.ticketTitle ?? "No Title", style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: rating != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(rating.score.toStringAsFixed(1)),
                        ],
                      ),
                      Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '"${rating.feedback}"',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  )
                      : const Text("No rating"),
                ),
              );
            },
          ),
        )
            : const Text("No tickets found."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}

