import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/faq.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/message.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/user.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:golden_ticket_enterprise/models/class_enums.dart';

class SignalRService with ChangeNotifier {
  HubConnection? _hubConnection;
  VoidCallback? onConnected;

  Function(List<MainTag>)? onTagUpdate;
  Function(Message, Chatroom)? onReceiveMessage;
  Function(List<FAQ>)? onFAQUpdate;
  Function(Chatroom)? onChatroomUpdate;
  Function(List<Chatroom>)? onChatroomsUpdate;
  Function(List<MainTag>)? onTicketUpdate;
  Function(Chatroom)? onReceiveSupport;
  Function(int, int)? onSeenUpdate;
  Function()? onAllowMessage;
  Function()? onMaximumChatroom;
  ConnectionType _connectionState = ConnectionType.disconnected;
  ConnectionType get connectionState => _connectionState;

  bool get isConnected => _connectionState == ConnectionType.connected;

  final String serverUrl = "http://${kBaseURL}/${kGTHub}";
  int _retryCount = 0; // For exponential backoff
  bool _shouldReconnect = true; // ✅ Prevents reconnecting after logout


  /// Initializes the SignalR connection
  Future<void> initializeConnection(User user) async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(
      serverUrl,
      HttpConnectionOptions(logging: (level, message) => print(message)), // Debug logs
    )
        .build();

    _hubConnection!.serverTimeoutInMilliseconds = 30000;
    _hubConnection!.keepAliveIntervalInMilliseconds = 5000;

    _hubConnection!.onclose((error) {
      print("❌ SignalR Connection Closed: $error");
      _updateConnectionState(ConnectionType.disconnected);
      if (_shouldReconnect) _attemptReconnect(); // ✅ Only retry if allowed
    });

    _hubConnection!.onreconnecting((error) {
      print("🔄 Reconnecting... Error: $error");
      _updateConnectionState(ConnectionType.reconnecting);
    });

    _hubConnection!.onreconnected((connectionId) async {
      print("✅ Reconnected: $connectionId");
      _retryCount = 0; // Reset retry count on successful reconnection
      _updateConnectionState(ConnectionType.connected);
      var userSession = Hive.box<HiveSession>('sessionBox').get('user');
      await _hubConnection!.invoke("Online", args: [userSession!.user.userID, userSession!.user.role]);
    });

    _setupEventHandlers();

    await startConnection();
  }

  void requestChat(int userID){
    try {
      _hubConnection!.invoke('RequestChat', args: [userID]);
    }catch(err){
      log("There was an error caught while requesting support: $err");
    }
  }
  void openChatroom(int userID, int chatroomID){
    try {
      _hubConnection!.invoke('OpenChatroom', args: [userID, chatroomID]);
    }catch(err){
      log("There was an error caught while opening chatroom: $err");
    }
  }
  void addMainTag(String tagName){
    try {
      _hubConnection!.invoke('AddMainTag', args: [tagName]);
    }catch(err){
      log("There was an error caught while saving tag: $err");
    }
  }
  void addSubTag(String tagName, String mainTagName){
    try{
      _hubConnection!.invoke('AddSubTag', args: [tagName, mainTagName]);
    }catch(err){
      log("There was an error caught while saving tag: $err");
    }
  }
  void sendMessage(int userID, int chatroomID, String messageContent) {
    try{
      _hubConnection!.invoke('SendMessage', args: [userID, chatroomID, messageContent]);
    }catch(err){
      log("There was an error caught while sending message: $err");
    }
  }
  void sendSeen(int userID, int chatroomID){
    try{
      _hubConnection!.invoke('UserSeen', args: [userID, chatroomID]);
    }catch(err){
      log("There was an error caught while sending message: $err");
    }
  }
  /// Sets up SignalR event handlers
  void _setupEventHandlers() {

    _hubConnection!.on('MaximumChatroom', (arguments){
      onMaximumChatroom?.call();
      notifyListeners();
    });

    _hubConnection!.on('UserSeen', (arguments){
        if(arguments != null){
          int chatroomID = arguments[0]['chatroomID'];
          int userID = arguments[0]['userID'];


          onSeenUpdate?.call(userID, chatroomID);
          notifyListeners();
        }
    });
    _hubConnection!.on('AllowMessage', (arguments){
      onAllowMessage?.call();
      notifyListeners();
    });
    _hubConnection!.on('ReceiveMessages', (arguments){

      if(arguments != null){
        var chatroomData = arguments[0]['chatroom'];
          Chatroom chatroom = Chatroom.fromJson(chatroomData);
          print(chatroom.messages!.length);
          onChatroomUpdate?.call(chatroom);
      }
      notifyListeners();
    });

    _hubConnection!.on('ReceiveMessage', (arguments){
      if(arguments != null) {

        onReceiveMessage?.call(Message.fromJson(arguments[0]['message']), Chatroom.fromJson(arguments[0]['chatroom']));
      }
    });

    _hubConnection!.on('ReceiveSupport', (arguments) {
      if(arguments != null){
        onChatroomUpdate?.call(Chatroom.fromJson(arguments[0]['chatroom']));
        onReceiveSupport?.call(Chatroom.fromJson(arguments[0]['chatroom']));
        notifyListeners();
      }
    });
    _hubConnection!.on('ChatroomUpdate', (arguments) {
      if(arguments != null){
        print(arguments[0]['chatroom']);

        onChatroomUpdate?.call(Chatroom.fromJson(arguments[0]['chatroom']));
        notifyListeners();
      }
    });
    _hubConnection!.on('TagUpdate', (arguments){

      if(arguments != null) {
        List<MainTag> updatedTags =
        (arguments[0]['tags'] as List)
            .map((tag) => MainTag.fromJson(tag))
            .toList();
        print("🔹 Updated Tags: ${updatedTags.length}");

        onTagUpdate?.call(updatedTags);
      }
    });
    _hubConnection!.on('Online', (arguments) {
      print("🔔 SignalR Event: Online Received!");
      if (arguments != null) {
        List<MainTag> updatedTags =
        (arguments[0]['tags'] as List).map((tag) => MainTag.fromJson(tag)).toList();

        List<FAQ> updatedFAQs =
        (arguments[0]['faq'] as List).map((faq) => FAQ.fromJson(faq)).toList();
        List<Chatroom> updatedChatrooms =
        (arguments[0]['chatrooms'] as List).map((chatroom) => Chatroom.fromJson(chatroom)).toList();

        print("🔹 Updated Tags: ${updatedTags.length}");
        print("🔹 Updated FAQs: ${updatedFAQs.length}");
        print("🔹 Updated Chatrooms: ${updatedChatrooms.length}");
        onTagUpdate?.call(updatedTags);
        onFAQUpdate?.call(updatedFAQs);
        onChatroomsUpdate?.call(updatedChatrooms);
      }
    });
  }

  /// Starts the SignalR connection
  Future<void> startConnection() async {

    if (_hubConnection == null) return;

    try {
      _shouldReconnect = true; // ✅ Allow reconnects on normal use
      _updateConnectionState(ConnectionType.connecting);
      await _hubConnection!.start();
      print("✅ SignalR Connected!");
      _updateConnectionState(ConnectionType.connected);
      onConnected?.call();

      print("🔄 Invoking Online Event...");

      var userSession = Hive.box<HiveSession>('sessionBox').get('user');
      await _hubConnection!.invoke("Online", args: [userSession!.user.userID, userSession!.user.role]);
    } catch (e) {
      print("❌ Error connecting to SignalR: $e");
      _updateConnectionState(ConnectionType.disconnected);
      if (_shouldReconnect) _attemptReconnect(); // ✅ Check flag before retrying
    }
  }

  /// Attempt to reconnect with exponential backoff
  Future<void> _attemptReconnect() async {
    if (!_shouldReconnect || _connectionState == ConnectionType.connected) return;

    _retryCount++;
    int delay = (5 * _retryCount).clamp(5, 30); // Delay increases but max 30 sec
    print("🕐 Retrying in $delay seconds... (Attempt: $_retryCount)");

    await Future.delayed(Duration(seconds: delay));
    await startConnection();
  }

  /// Manually trigger reconnection
  Future<void> reconnect() async {
    print("🔁 Manual Reconnect Triggered...");
    _shouldReconnect = true; // ✅ Ensure manual reconnects are allowed
    _retryCount = 0;
    await startConnection();
  }

  /// Stops the SignalR connection and prevents reconnection
  Future<void> stopConnection() async {
    if (_hubConnection != null) {
      _shouldReconnect = false;
      log("SignalR: Stopping connection...");
      await _hubConnection!.stop();
      _hubConnection = null; // Ensure it's fully cleared
    }
  }


  /// Updates connection state and notifies listeners
  void _updateConnectionState(ConnectionType state) {
    _connectionState = state;
    notifyListeners();
  }

  /// Dispose method to properly clean up connection
  @override
  void dispose() {
    stopConnection();
    super.dispose();
  }
}
