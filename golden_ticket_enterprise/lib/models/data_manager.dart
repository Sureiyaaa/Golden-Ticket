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
  List<String> status = [];
  List<Chatroom> chatrooms = [];
  List<Ticket> tickets = [];
  List<User> users = [];
  List<String> priorities = [];
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
      updateLastMessage(chatroom);
    };
    signalRService.onSeenUpdate = (userID, chatroomID){
      updateMemberSeen(userID, chatroomID);
    };
    signalRService.onTicketUpdate = (ticket){
      updateTicket(ticket);
    };
    signalRService.onTicketsUpdate = (updatedTickets){
      updateTickets(updatedTickets);
    };

    signalRService.onStatusUpdate = (updatedStatus){
      updateStatus(updatedStatus);
    };
    signalRService.onStaffJoined = (user, chatroom){
      updateChatroom(chatroom);

    };
    signalRService.onPriorityUpdate = (updatedPriorities){
      updatePriorities(updatedPriorities);
    };
    signalRService.onUsersUpdate = (updatedUsers){
      updateUsers(updatedUsers);
    };
  }

  void updateMainTags(List<MainTag> updatedTags) {
    mainTags = updatedTags;
    notifyListeners();
  }
  void updatePriorities(List<String> updatedPriorities){
    priorities = updatedPriorities;
    notifyListeners();
  }

  void updateFAQs(List<FAQ> updatedFAQs) {
    faqs = updatedFAQs;
    notifyListeners();
  }

  void updateUsers(List<User> updatedUsers) {
    users = updatedUsers;
    notifyListeners();
  }

  void updateStatus(List<String> updatedStatus){
    status = updatedStatus;
    notifyListeners();
  }
  void updateTickets(List<Ticket> updatedTickets){
    tickets = updatedTickets;
    tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }
  void updateChatrooms(List<Chatroom> chatroomList){
    chatrooms = chatroomList;
    chatrooms.sort((a, b) => b.lastMessage?.createdAt?.compareTo(a.lastMessage?.createdAt ?? DateTime(0)) ?? 0);
    notifyListeners();
  }
  void updateLastMessage(Chatroom chatroom){
    int index = chatrooms.indexWhere((c) => c.chatroomID == chatroom.chatroomID);

    if (index != -1) {
      chatrooms[index].lastMessage = chatroom.lastMessage;
    }
    chatrooms.sort((a, b) {
      DateTime? aTime = a.lastMessage?.createdAt;
      DateTime? bTime = b.lastMessage?.createdAt;

      // If one of the messages is null, place the chatroom without messages at the bottom
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      return bTime.compareTo(aTime); // Newest first
    });

    notifyListeners();
  }

  void addMessage(message, chatroom){
    int index = chatrooms.indexWhere((c) => c.chatroomID == chatroom.chatroomID);

    if (index != -1) {
      chatrooms[index].messages!.add(message);
      chatrooms[index].messages!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    updateLastMessage(chatroom);
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
    if (index != -1) {
      // Keep existing messages if the new chatroom's messages are null
      List<Message>? existingMessages = chatrooms[index].messages;
      Ticket? existingTicket = chatrooms[index].ticket;
      chatrooms[index] = chatroom;
      if (chatroom.ticket == null) {
        chatrooms[index].ticket = existingTicket;
      }

      if (chatroom.messages!.length == 0) {
        chatrooms[index].messages = existingMessages; // Retain old messages
      }
    } else {
      chatrooms.add(chatroom);
    }
    chatrooms.sort((a, b) => b.lastMessage?.createdAt?.compareTo(a.lastMessage?.createdAt ?? DateTime(0)) ?? 0);
    notifyListeners();
  }
  void updateTicket(Ticket ticket) {
    int index = tickets.indexWhere((c) => c.ticketID == ticket.ticketID);
    if (index != -1) {
      tickets[index] = ticket;  // Update chatroom
    } else {
      tickets.add(ticket);
    }

    tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  @override
  void dispose() {
    closeConnection(); // Ensure cleanup
    super.dispose();
  }
  List<User> getAgents(){
    return users.where((user) => user.role != "Employee").toList();
  }

  Chatroom? findChatroom(Chatroom chatroom) {
    return chatrooms.firstWhere(
          (c) => c.chatroomID == chatroom.chatroomID);
  }


  Chatroom? findChatroomByID(int chatroomID) {
    return chatrooms.firstWhere(
            (c) => c.chatroomID == chatroomID);
  }

  Chatroom? findChatroomByTicketID(int ticketID){
    return chatrooms.firstWhere(
            (c) => c.ticket?.ticketID == ticketID);
  }

  Future<void> closeConnection() async {
    tickets = [];
    mainTags = [];
    status = [];
    chatrooms = [];
    users = [];
    faqs = [];
    await signalRService.stopConnection();
  }
}
