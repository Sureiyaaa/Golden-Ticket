import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/models/chatroom.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';

class ChatroomView extends StatefulWidget {
  final String chatroomID;

  const ChatroomView({super.key, required this.chatroomID});

  @override
  State<ChatroomView> createState() => _ChatroomViewState();
}

class _ChatroomViewState extends State<ChatroomView> {
  late Chatroom chatroom; // Holds chatroom details

  @override
  void initState() {
    super.initState();
    chatroom = Chatroom.dummy(); // Load dummy data for now
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kPrimary,
            title: Text("${chatroom.openerName}'s Chatroom"), // Chatroom named after opener
            actions: [
              IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () => _openTicketInfo(),
              ),
            ],
          ),
          endDrawer: _ticketInfoDrawer(), // Ticket info drawer
          body: Column(
            children: [
              // Clickable Ticket Info
              InkWell(
                onTap: _openTicketInfo,
                child: Container(
                  padding: EdgeInsets.all(16),
                  color: kPrimaryContainer.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🎟 Ticket Title: ${chatroom.ticketTitle}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("📌 Status: ${chatroom.ticketStatus}",
                          style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      SizedBox(height: 4),
                      Text("👤 Opened by: ${chatroom.openerName}",
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              Divider(),

              // Chatroom Messages (Placeholder for now)
              Expanded(
                child: Center(
                  child: Text("Chat messages will appear here...",
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ),
              ),

              // Message Input
              Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: kPrimary),
                      onPressed: () {
                        // Future: Send message functionality
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  /// Opens the ticket details drawer
  void _openTicketInfo() {
    Scaffold.of(context).openEndDrawer();
  }

  /// Ticket Information Drawer
  Widget _ticketInfoDrawer() {
    return Drawer(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📄 Ticket Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text("🎟 Ticket ID: ${chatroom.ticketID}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("📝 Title: ${chatroom.ticketTitle}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("📌 Status: ${chatroom.ticketStatus}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("👤 Opener: ${chatroom.openerName}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("📋 Description:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  chatroom.ticketDescription,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
