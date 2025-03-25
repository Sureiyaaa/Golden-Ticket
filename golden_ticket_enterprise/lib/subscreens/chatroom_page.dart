import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:provider/provider.dart';

import '../models/hive_session.dart';

class ChatroomListPage extends StatelessWidget {
  final HiveSession? session;
  const ChatroomListPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        return Scaffold(
          backgroundColor: kSurface,
          body: dataManager.chatrooms.isEmpty
              ? Center(
            child: Text(
              "No chatrooms available",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
              : ListView.builder(
            itemCount: dataManager.chatrooms.length,
            itemBuilder: (context, index) {
              Chatroom chatroom = dataManager.chatrooms[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                  title: Text(chatroom.chatroomName, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Opened by: ${chatroom.author.firstName} ${chatroom.author.lastName}"),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  onTap: () => context.go("/hub/chatroom/${1}"),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
