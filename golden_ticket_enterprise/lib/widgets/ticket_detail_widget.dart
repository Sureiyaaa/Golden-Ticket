import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/styles/icons.dart';

class TicketDetailsPopup extends StatelessWidget {
  final Ticket ticket;

  const TicketDetailsPopup({Key? key, required this.ticket}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${ticket.ticketID}: ${ticket.ticketTitle ?? "No title provided"}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: kPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Author: ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                            '${ticket.author.firstName} ${ticket.author.lastName}',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Assigned: ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          ticket.assigned != null
                              ? '${ticket.assigned!.firstName} ${ticket.assigned!.lastName}'
                              : 'None assigned',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Priority: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Chip(
                              label: Text(ticket.priority,
                                  style: TextStyle(fontWeight: FontWeight.normal)),
                              backgroundColor:
                              getPriorityColor(ticket.priority),
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        if (ticket.mainTag != null)
                          Row(
                            children: [
                              Text('Main Tag: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              Chip(
                                label: Text(ticket.mainTag!.tagName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal)),
                                backgroundColor: Colors.redAccent,
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Text('Sub Tag: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Chip(
                              label: Text(
                                  ticket.subTag?.subTagName ??
                                      "No Sub Tag Provided",
                                  style: TextStyle(fontWeight: FontWeight.normal)),
                              backgroundColor: Colors.blueAccent,
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Text('Status: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Chip(
                              label: Text(ticket.status,
                                  style: TextStyle(fontWeight: FontWeight.normal)),
                              backgroundColor: getStatusColor(ticket.status),
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Created At: ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                            '${TimeUtil.formatCreationDate(ticket.createdAt)}',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Ticket History Section with Background Separator
                    Text('Ticket History',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[350], // Light background color
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Container(
                        height: 200,
                        child: ListView.builder(
                          itemCount: ticket.ticketHistory?.length ?? 0,
                          itemBuilder: (context, index) {
                            var sortedHistory = ticket.ticketHistory!
                              ..sort((a, b) =>
                                  b.actionDate.compareTo(a.actionDate));
                            var historyItem = sortedHistory[index];
                            bool isLast = index == sortedHistory.length - 1;

                            return Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 30,
                                    child: Column(
                                      children: [
                                        Icon(
                                            getActionHandlerIcon(
                                                historyItem.action),
                                            size: 24,
                                            color: kPrimary),
                                        if (!isLast)
                                          Container(
                                            width: 2,
                                            height: 60, // Increased for better flow
                                            color: kPrimary,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(left: 10),
                                      decoration: BoxDecoration(
                                        color: kPrimaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                            Colors.black.withOpacity(0.05),
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          )
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        title: Text(
                                          '${TimeUtil.formatCreationDate(historyItem.actionDate)}: ${historyItem.action}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        subtitle: Text(
                                            historyItem.actionMessage,
                                            style: TextStyle(fontSize: 14)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            backgroundColor: kPrimary,
                          ),
                          child: Text('Close', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
