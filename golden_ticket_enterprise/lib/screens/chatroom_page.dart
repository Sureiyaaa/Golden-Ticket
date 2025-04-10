import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/group_member.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/widgets/chatroom_details_widget.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
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

  @override
  void initState() {
    super.initState();
    messageFocusNode.requestFocus();
  }

  Widget build(BuildContext context) {

    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        Chatroom? chatroom = dataManager.findChatroomByID(widget.chatroomID);
        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
        String chatTitle = chatroom?.ticket != null ? chatroom?.ticket?.ticketTitle ?? "New Chat" : "New Chat";

        dataManager.signalRService.onReceiveMessage = (message, chatroom) {
          print(chatroom.chatroomID);
          if (chatroom.chatroomID == widget.chatroomID) {
            dataManager.signalRService.sendSeen(userSession!.user.userID, widget.chatroomID);
            dataManager.addMessage(message, chatroom);
          }
        };
        void sendMessage(String messageContent, Chatroom chatroom) {
          if (messageContent.trim().isEmpty) return;

          var userSession = Hive.box<HiveSession>('sessionBox').get('user');
          if (userSession == null) return;

          Provider.of<DataManager>(context, listen: false)
              .signalRService
              .sendMessage(userSession.user.userID, widget.chatroomID, messageContent);

          messageController.clear();
          if (chatroom.ticket == null) {
            setState(() {
              enableMessage = false;
            });
          }else{
            messageFocusNode.requestFocus();
          }
        }
        dataManager.signalRService.onAlreadyMember = (){
          TopNotification.show(
              context: context,
              message: "You are already a member of this group chat!",
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
              textColor: Colors.white,
              onTap: () {
                TopNotification.dismiss();
              }
          );
        };
        dataManager.signalRService.onAllowMessage = () {
          setState(() {
            enableMessage = true;
            messageFocusNode.requestFocus();
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
            title: Text('${chatTitle}'),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),
          endDrawer: ChatroomDetailsDrawer(chatroom: dataManager.findChatroomByID(widget.chatroomID)!),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  itemCount: chatroom.messages!.length,
                  itemBuilder: (context, index) {
                    final message = chatroom.messages![index];
                    final seenByMembers = chatroom.groupMembers!
                        .where((m) => m.lastSeenAt != null && m.lastSeenAt!.isAfter(message.createdAt))
                        .toList();

                    final isMe = message.sender.userID == userSession!.user.userID;
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
                              // Sender Name Above Message
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  "${message.sender.firstName}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              // Message Bubble with Dynamic Resizing
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Tooltip(
                                    message: TimeUtil.formatTimestamp(message.createdAt),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isMe ? kPrimaryContainer : kTertiaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth * 0.5, // ✅ 50% of available width
                                      ),
                                      child: MarkdownBody(
                                        data: message.messageContent, // ✅ Render Markdown
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(fontSize: 14, color: Colors.black),
                                          strong: const TextStyle(fontWeight: FontWeight.bold),
                                          blockquote: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                                        ),
                                        selectable: true,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (isSeen)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2, right: 12, left: 12),
                                  child: Text(
                                    _formatSeenBy(seenByMembers),
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
              if(chatroom.isClosed && chatroom.groupMembers!.any((u) => u.member?.userID == userSession?.user.userID))
                _buildReopenRoom(dataManager, userSession, chatroom)
              else if (chatroom.isClosed)
                _buildClosedBar(dataManager, userSession, chatroom)
              else if (chatroom.groupMembers!.any((u) => u.member?.userID == userSession?.user.userID))
                _buildMessageInput(chatroom, sendMessage)
              else
                _buildJoinRoomButton(dataManager, userSession, chatroom),
            ],
          ),
        );
      },
    );

  }

  Widget _buildMessageInput(Chatroom chatroom, Function(String message, Chatroom chatroom) sendMessage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              focusNode: messageFocusNode,
              keyboardType: TextInputType.multiline,
              maxLines: 4, // Expands up to 4 lines, then scrolls
              minLines: 1,
              textInputAction: TextInputAction.newline, // Allows multi-line
              enabled: enableMessage,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              onEditingComplete: () {
                // Ensures the message is sent when Enter is pressed
                (messageController.text.trim(), chatroom);
                messageController.clear();
                enableMessage = false;
              },
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.endsWith('\n') && !HardwareKeyboard.instance.isShiftPressed) {
                    sendMessage(newValue.text.trim(), chatroom);
                    return TextEditingValue.empty;
                  }
                  return newValue;
                }),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: enableMessage ? Colors.blue : Colors.grey),
            onPressed: enableMessage ? () => sendMessage(messageController.text.trim(), chatroom) : null,
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
  Widget _buildReopenRoom(DataManager dataManager, HiveSession? userSession, Chatroom chatroom) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
        onPressed: () {
          if (userSession != null) {
            dataManager.signalRService.reopenChatroom(userSession.user.userID, chatroom.chatroomID);
          }
        },
        child: Text("Reopen Chatroom"),
      ),
    );
  }
  Widget _buildClosedBar(DataManager dataManager, HiveSession? userSession, Chatroom chatroom) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child:  Text("Viewing archived chat"),
    );
  }

  String _formatSeenBy(List<GroupMember> seenBy) {
    return seenBy.map((u) => u.member!.firstName).join(", ");
  }
}
