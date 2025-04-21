import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/group_member.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
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
  bool includeClosedChatrooms = false;
  bool includeMyChatrooms = false;
  bool showFilters = false;

  int currentPage = 0;
  final int itemsPerPage = 10;

  TextEditingController searchController = TextEditingController();

  void resetPagination() {
    setState(() {
      currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        dataManager.signalRService.onReceiveSupport = (chatroom) {
          context.push('/hub/chatroom/${chatroom.chatroomID}');
        };

        List<Chatroom> filteredChatrooms = dataManager.chatrooms.where((chatroom) {
          String chatTitle = chatroom.ticket != null
              ? chatroom.ticket?.ticketTitle ?? "No title provided"
              : "No title provided";
          String chatroomAuthor = chatroom.author != null
              ? "${chatroom.author!.firstName} ${chatroom.author!.lastName}"
              : "Unknown Author";

          bool matchesQuery = chatTitle.toLowerCase().contains(searchQuery.toLowerCase()) ||
              chatroomAuthor.toLowerCase().contains(searchQuery.toLowerCase());

          bool isClosed = chatroom.isClosed;
          bool isMyChatroom = chatroom.groupMembers!
              .any((member) => member.member?.userID == widget.session!.user.userID);

          return matchesQuery &&
              (includeClosedChatrooms || !isClosed) &&
              (!includeMyChatrooms || isMyChatroom);
        }).toList();

        List<Chatroom> paginatedChatrooms = filteredChatrooms
            .skip(currentPage * itemsPerPage)
            .take(itemsPerPage)
            .toList();

        int totalPages = (filteredChatrooms.length / itemsPerPage).ceil();

        return Scaffold(
          floatingActionButton: widget.session!.user.role == "Employee"
              ? FloatingActionButton(
            heroTag: "chat_request",
            tooltip: widget.session!.user.role == "Employee" ? "Request Chat" : "Add FAQ",
            onPressed: () {
              dataManager.signalRService.requestChat(widget.session!.user.userID);
            },
            child: Icon(Icons.chat),
            backgroundColor: kPrimary,
          )
              : null,
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
                  resetPagination();
                });
              },
            ),
            actions: [
              if (searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.black38),
                  onPressed: () {
                    setState(() {
                      searchQuery = "";
                      searchController.clear();
                      resetPagination();
                    });
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              ExpansionTile(
                title: Text(
                  "Filters",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                initiallyExpanded: showFilters,
                onExpansionChanged: (value) {
                  setState(() {
                    showFilters = value;
                  });
                },
                children: [
                  CheckboxListTile(
                    title: Text("Include Closed Chatrooms"),
                    value: includeClosedChatrooms,
                    onChanged: (bool? value) {
                      setState(() {
                        includeClosedChatrooms = value ?? true;
                        resetPagination();
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text("My Chatrooms"),
                    value: includeMyChatrooms,
                    onChanged: (bool? value) {
                      setState(() {
                        includeMyChatrooms = value ?? true;
                        resetPagination();
                      });
                    },
                  ),
                ],
              ),
              Expanded(
                child: paginatedChatrooms.isEmpty
                    ? Center(
                  child: Text(
                    "No chatrooms found",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: paginatedChatrooms.length,
                  itemBuilder: (context, index) {
                    Chatroom chatroom = paginatedChatrooms[index];
                    String chatTitle = chatroom.ticket != null
                        ? chatroom.ticket?.ticketTitle ?? "No Title Provided"
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

                    GroupMember? currentUser;
                    final matchingMembers = chatroom.groupMembers!
                        .where((member) => member.member?.userID == widget.session!.user.userID);
                    bool isUnread = false;
                    if (matchingMembers.isNotEmpty) {
                      currentUser = matchingMembers.first;
                    }
                    if (currentUser == null) {
                      isUnread = true;
                    } else if (currentUser.lastSeenAt == null ||
                        currentUser.lastSeenAt!.isBefore(chatroom.lastMessage!.createdAt!)) {
                      isUnread = true;
                    }

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (isUnread)
                            BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                        ],
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Material(
                          color: isUnread ? Colors.white : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            hoverColor: Colors.black.withOpacity(0.15),
                            splashColor: kPrimary.withOpacity(0.15),
                            highlightColor: Colors.transparent,
                            onTap: () {
                              context.push('/hub/chatroom/${chatroom.chatroomID}');
                              dataManager.signalRService.openChatroom(
                                  widget.session!.user.userID, chatroom.chatroomID);
                            },
                            child: Row(
                              children: [
                                if (isUnread)
                                  Container(
                                    width: 5,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                  ),
                                if (!isUnread) SizedBox(width: 5),
                                Expanded(
                                  child: ListTile(
                                    contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                      isUnread ? Colors.red : Colors.grey,
                                      child: Icon(Icons.chat_bubble_outline,
                                          color: Colors.white),
                                    ),
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chatTitle,
                                          style: TextStyle(
                                            fontWeight: isUnread
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "By: $chatroomAuthor",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Expanded(child: _buildLastMessage(lastMessage, isUnread)),
                                          if (messageTime.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: Text(
                                                messageTime,
                                                style: TextStyle(
                                                    color: Colors.grey, fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    trailing: Icon(Icons.arrow_forward_ios,
                                        size: 18, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (filteredChatrooms.length > itemsPerPage)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: currentPage > 0
                            ? () {
                          setState(() {
                            currentPage--;
                          });
                        }
                            : null,
                      ),
                      Text("Page ${currentPage + 1} of $totalPages"),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: currentPage < totalPages - 1
                            ? () {
                          setState(() {
                            currentPage++;
                          });
                        }
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLastMessage(String messageContent, bool isUnread) {
    String cleanedMessage = messageContent.replaceAll("\n", " ");

    return MarkdownBody(
      data: cleanedMessage,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
        strong: TextStyle(fontWeight: FontWeight.bold),
        em: TextStyle(fontStyle: FontStyle.italic),
        blockquote: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
      ),
      selectable: false,
    );
  }
}
