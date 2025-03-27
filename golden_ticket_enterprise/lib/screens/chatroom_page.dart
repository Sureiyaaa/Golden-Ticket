import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/group_member.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
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
    if(chatroom.ticket == null) {
      setState(() {
        enableMessage = false;
      });
    }
  }
  @override
  void initState(){
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
        dataManager.signalRService.onAllowMessage = (){
          print('Yes');
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
                    final seenByMembers = chatroom.groupMembers
                        .where((m) => m.lastSeenAt != null && m.lastSeenAt!.isAfter(message.createdAt))
                        .toList();

                    final isMe = message!.sender.userID == userSession!.user.userID;
                    final isSeen = seenByMembers.isNotEmpty && seenMessageID == message.messageID;


                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              seenMessageID = (seenMessageID == message.messageID) ? null : message.messageID;
                            });
                          },
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
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
                                    maxWidth: MediaQuery.of(context).size.width * 0.75, // Prevents full row width
                                  ),
                                  child: Text(message.messageContent),
                                ),
                              ),
                              if (isSeen)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2, right: 12, left: 12),
                                  child: Text(
                                    _formatSeenBy(chatroom.groupMembers
                                        .where((m) => m.lastSeenAt != null && m.lastSeenAt!.isAfter(message.createdAt))
                                        .toList()
                                    ),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildMessageInput(chatroom),
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
            icon: const Icon(Icons.send, color: Colors.blue),
            disabledColor: Colors.grey,
            onPressed: enableMessage ? null: () => sendMessage(messageController.text, chatroom), // ✅ Calls sendMessage on click
          ),
        ],
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



class ChatroomDetailsDrawer extends StatelessWidget {
  final Chatroom chatroom;

  const ChatroomDetailsDrawer({Key? key, required this.chatroom}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kPrimaryContainer,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: kPrimary),
            child: Text(
              '${chatroom.author.firstName} ${chatroom.author.lastName}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Created By"),
            subtitle: Text('${chatroom.author.firstName} ${chatroom.author.lastName}' ?? "Unknown"),
          ),
          ExpansionTile(
            leading: const Icon(Icons.people),
            title: const Text("Members"),
            subtitle: Text("${chatroom.groupMembers.length} members"),
            children: chatroom.groupMembers.map((member) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text("${member.member!.firstName} ${member.member!.lastName}"),
                subtitle: Text(TimeUtil.formatCreationDate(member.joinedAt!)),
              );
            }).toList(),
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text("Date Created"),
            subtitle: Text(TimeUtil.formatCreationDate(chatroom.createdAt.toLocal())),
          ),
        ],
      ),
    );
  }
}
