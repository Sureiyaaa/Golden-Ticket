import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/group_member.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/widgets/chatroom_details_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class ChatroomPage extends StatefulWidget {
  final int chatroomID;

  const ChatroomPage({Key? key, required this.chatroomID}) : super(key: key);

  @override
  _ChatroomPageState createState() => _ChatroomPageState();
}

class _ChatroomPageState extends State<ChatroomPage> {
  int? seenMessageID;
  TextEditingController messageController = TextEditingController();
  FocusNode messageFocusNode = FocusNode();
  bool enableMessage = true;
  bool _isInitialized = false;
  late DataManager _dataManager;

  void sendMessage(String messageContent, Chatroom chatroom) {
    if (messageContent.trim().isEmpty) return; // Prevent empty messages

    var userSession = Hive.box<HiveSession>('sessionBox').get('user');
    if (userSession == null) return; // Ensure user session exists

    Provider.of<DataManager>(context, listen: false)
        .signalRService
        .sendMessage(userSession.user.userID, widget.chatroomID, messageContent);

    messageController.clear(); // Clear input field after sending
    if (chatroom.ticket == null) {
      setState(() {
        enableMessage = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    messageFocusNode.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _dataManager = Provider.of<DataManager>(context, listen: false);

      if (!_dataManager.signalRService.isConnected) {
        log("HubPage: Initializing SignalR Connection...");

        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
        _dataManager.signalRService.initializeConnection(userSession!.user);
      }

      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        Chatroom? chatroom = dataManager.findChatroomByID(widget.chatroomID);

        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
        dataManager.signalRService.onReceiveMessage = (message, chatroom) {
          if (chatroom.chatroomID == widget.chatroomID) {
            dataManager.signalRService.sendSeen(userSession!.user.userID, widget.chatroomID);
            dataManager.addMessage(message, chatroom);
          }
        };
        dataManager.signalRService.onAllowMessage = () {
          setState(() {
            enableMessage = true;
          });
        };

        if (chatroom == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Chatroom Not Found")),
            body: const Center(child: Text("Chatroom does not exist or failed to load.")),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: kPrimary,
            title: Text('${chatroom.author.firstName} ${chatroom.author.lastName}'),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),
          endDrawer: ChatroomDetailsDrawer(chatroom: chatroom),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  itemCount: chatroom.messages!.length,
                  itemBuilder: (context, index) {
                    final message = chatroom.messages![index];
                    final previousMessage = index < chatroom.messages!.length - 1
                        ? chatroom.messages![index + 1]
                        : null;

                    final isMe = message!.sender.userID == userSession!.user.userID;

                    // Check if time difference is greater than 1 hour and 30 minutes
                    bool shouldShowTimeSeparator = false;
                    if (previousMessage != null) {
                      final timeDifference = previousMessage!.createdAt.difference(message.createdAt);
                      if (timeDifference.inMinutes > 90) {
                        shouldShowTimeSeparator = true;
                      }
                    }

                    return Column(
                      children: [
                        if (shouldShowTimeSeparator)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              TimeUtil.formatTimestamp(message.createdAt),
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, right: 12, top: 6),
                                    child: Text(
                                      isMe ? "You" : "${message.sender.firstName} ${message.sender.lastName}",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                    ),
                                  ),
                                  Tooltip(
                                    message: TimeUtil.formatTimestamp(message.createdAt),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isMe ? kPrimaryContainer : kTertiaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.4,
                                      ),
                                      child: SelectableText(message.messageContent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (chatroom.groupMembers.any((u) => u.member?.userID == userSession?.user.userID))
                _buildMessageInput(chatroom)
              else
                _buildJoinRoomButton(dataManager, userSession, chatroom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(Chatroom chatroom) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              enabled: enableMessage,
              onSubmitted: (text) => sendMessage(text, chatroom), // ✅ Calls sendMessage on Enter key
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: enableMessage ? Colors.blueAccent : Colors.grey),
            disabledColor: Colors.grey,
            onPressed: enableMessage ? () => sendMessage(messageController.text, chatroom) : null, // ✅ Calls sendMessage on click
          ),
        ],
      ),
    );
  }
  Widget _buildJoinRoomButton(DataManager dataManager, HiveSession? userSession, Chatroom chatroom) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
        onPressed: () {
          if (userSession != null) {
            dataManager.signalRService.joinChatroom(userSession.user.userID, chatroom.chatroomID);
          }
        },
        child: Text("Join Room"),
      ),
    );
  }

  String _formatSeenBy(List<GroupMember> seenBy) {
    if (seenBy.isEmpty) return "You";

    var userSession = Hive.box<HiveSession>('sessionBox').get('user');
    if (seenBy.length <= 3) {
      return seenBy.map((u) => u.member!.userID == userSession!.user.userID ? "You" : u.member!.firstName).join(", ");
    } else {
      final firstThree = seenBy.take(3).map((u) => u.member!.userID == userSession!.user.userID ? "You" : u.member!.firstName).join(", ");
      final othersCount = seenBy.length - 3;
      return "$firstThree and $othersCount others";
    }
  }
}

