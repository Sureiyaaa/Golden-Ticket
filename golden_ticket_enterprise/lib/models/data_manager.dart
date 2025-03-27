import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/faq.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/message.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/models/signalr_service.dart';

class DataManager extends ChangeNotifier {
  final SignalRService signalRService;
  List<MainTag> mainTags = [];
  List<FAQ> faqs = [];
  List<Chatroom> chatrooms = [];
  List<Ticket> tickets = [];
  List<User> users = [];

  DataManager({required this.signalRService}) {
    _initializeSignalR();
  }

  void _initializeSignalR() {
    if (!signalRService.isConnected) {
      signalRService.onConnected = () {
        print("SignalR Connected! Attaching Events...");
        attachSignalREvents();
      };

      signalRService.startConnection(); // Start connection
    } else {
      attachSignalREvents();
    }
    signalRService.addListener(() {
      Future.microtask(() {
        notifyListeners(); // Ensures this runs after the current build completes
      });
    });
  }

  void attachSignalREvents() {
    signalRService.onTagUpdate = (updatedTags) {
      updateMainTags(updatedTags);
    };
    signalRService.onFAQUpdate = (updatedFAQs) {
      updateFAQs(updatedFAQs);
    };
    signalRService.onChatroomsUpdate = (updatedChatrooms){
      updateChatrooms(updatedChatrooms);
    };
    signalRService.onChatroomUpdate = (updatedChatroom){
      updateChatroom(updatedChatroom);
    };

    signalRService.onReceiveMessage = (message, chatroom){
      updateLastMessage(chatroom as Chatroom);
    };
    signalRService.onSeenUpdate = (userID, chatroomID){
      updateMemberSeen(userID, chatroomID);
    };
  }

  void updateMainTags(List<MainTag> updatedTags) {
    mainTags = updatedTags;
    notifyListeners();
  }

  void updateFAQs(List<FAQ> updatedFAQs) {
    faqs = updatedFAQs;
    notifyListeners();
  }
  void updateChatrooms(List<Chatroom> chatroomList){
    chatrooms = chatroomList;
    notifyListeners();
  }
  void updateLastMessage(Chatroom chatroom){
    int index = chatrooms.indexWhere((c) => c.chatroomID == chatroom.chatroomID);

    if (index != -1) {
      chatrooms[index].lastMessage = chatroom.lastMessage;
    }
  }
  void addMessage(message, chatroom){
    int index = chatrooms.indexWhere((c) => c.chatroomID == chatroom.chatroomID);

    if (index != -1) {
      chatrooms[index].messages!.add(message);
      chatrooms[index].messages!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    notifyListeners();
  }

  void updateMemberSeen(int userID, int chatroomID){
    int chatroomIndex = chatrooms.indexWhere((c) => c.chatroomID == chatroomID);

    if (chatroomIndex != -1) {
      int memberIndex = chatrooms[chatroomIndex].groupMembers.indexWhere((m) => m.member!.userID == userID);

      if (memberIndex != -1) { // Ensure member exists
        chatrooms[chatroomIndex].groupMembers[memberIndex].lastSeenAt = DateTime.now();
        notifyListeners();
      }
    }
  }


  void updateChatroom(Chatroom chatroom) {
    int index = chatrooms.indexWhere((c) => c.chatroomID == chatroom.chatroomID);
    print('Yes');
    if (index != -1) {
      // Keep existing messages if the new chatroom's messages are null
      List<Message>? existingMessages = chatrooms[index].messages;

      chatrooms[index] = chatroom;  // Update chatroom

      if (chatroom.messages == null) {
        chatrooms[index].messages = existingMessages; // Retain old messages
      }
    } else {
      chatrooms.add(chatroom);
    }
    chatrooms.sort((a, b) => b.lastMessage!.createdAt!.compareTo(a.lastMessage!.createdAt!));
    notifyListeners();
  }


  @override
  void dispose() {
    signalRService.stopConnection(); // Ensure cleanup
    super.dispose();
  }

  Chatroom? findChatroom(Chatroom chatroom) {
    return chatrooms.firstWhere(
          (c) => c.chatroomID == chatroom.chatroomID);
  }


  Chatroom? findChatroomByID(int chatroomID) {
    return chatrooms.firstWhere(
            (c) => c.chatroomID == chatroomID);
  }
}
