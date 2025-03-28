import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart'; // ✅ Import TimeUtil
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:provider/provider.dart';

import '../models/hive_session.dart';

class ChatroomListPage extends StatefulWidget {
  final HiveSession? session;
  const ChatroomListPage({super.key, required this.session});

  @override
  _ChatroomListPageState createState() => _ChatroomListPageState();
}

class _ChatroomListPageState extends State<ChatroomListPage> {
  String searchQuery = "";
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        List<Chatroom> filteredChatrooms = dataManager.chatrooms.where((chatroom) {
          String chatTitle = chatroom.ticket != null ? chatroom.ticket!.ticketTitle : "No title provided";
          String chatroomAuthor = chatroom.author != null
              ? "${chatroom.author!.firstName} ${chatroom.author!.lastName}"
              : "Unknown Author";

          return chatTitle.toLowerCase().contains(searchQuery.toLowerCase()) ||
              chatroomAuthor.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

        return Scaffold(
          backgroundColor: kSurface,
          appBar: AppBar(
            backgroundColor: kPrimaryContainer,
            title: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search chatrooms...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.black54),
              ),
              style: TextStyle(color: Colors.black),
              cursorColor: Colors.black54,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            actions: [
              if (searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      searchQuery = "";
                      searchController.clear();
                    });
                  },
                ),
            ],
          ),
          body: filteredChatrooms.isEmpty
              ? Center(
            child: Text(
              "No chatrooms found",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
              : ListView.builder(
            itemCount: filteredChatrooms.length,
            itemBuilder: (context, index) {
              Chatroom chatroom = filteredChatrooms[index];
              String chatTitle = chatroom.ticket != null
                  ? chatroom.ticket!.ticketTitle
                  : "No title provided";
              String chatroomAuthor = chatroom.author != null
                  ? "${chatroom.author!.firstName} ${chatroom.author!.lastName}"
                  : "Unknown Author";
              bool hasLastMessage = chatroom.lastMessage != null;
              String lastMessage = hasLastMessage
                  ? "${chatroom.lastMessage!.sender!.firstName}: ${chatroom.lastMessage!.messageContent}"
                  : "No messages yet";
              String messageTime = hasLastMessage
                  ? TimeUtil.formatTimestamp(chatroom.lastMessage!.createdAt!)
                  : "";

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chatTitle,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "By: $chatroomAuthor",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          ),
                        ),
                        if (messageTime.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              messageTime,
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  onTap: () {
                    context.push('/hub/chatroom/${chatroom.chatroomID}');
                    dataManager.signalRService.openChatroom(widget.session!.user.userID, chatroom.chatroomID);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
