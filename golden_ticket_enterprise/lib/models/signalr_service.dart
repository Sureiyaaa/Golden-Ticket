import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/faq.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/message.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/user.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:golden_ticket_enterprise/models/class_enums.dart';

class SignalRService with ChangeNotifier {
  HubConnection? _hubConnection;
  VoidCallback? onConnected;

  var logger = Logger();
  Function(List<MainTag>)? onTagUpdate;
  Function(Message, Chatroom)? onReceiveMessage;
  Function(List<FAQ>)? onFAQUpdate;
  Function(Chatroom)? onChatroomUpdate;
  Function(List<Chatroom>)? onChatroomsUpdate;
  Function(List<Ticket>)? onTicketsUpdate;
  Function(Ticket)? onTicketUpdate;
  Function(Chatroom)? onReceiveSupport;
  Function(List<String>)? onStatusUpdate;
  Function(int, int)? onSeenUpdate;
  Function(User, Chatroom)? onStaffJoined;
  Function()? onAllowMessage;
  Function()? onMaximumChatroom;
  Function()? onExistingTag;
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
      HttpConnectionOptions(logging: (level, message) {
        switch(level){
          case LogLevel.information:
              // logger.i(message);
            break;
          case LogLevel.trace:
            logger.t(message);
          case LogLevel.debug:
            logger.d(message);
          case LogLevel.warning:
            logger.w(message);
          case LogLevel.error:
            logger.e(message, error: "None Provided");
          case LogLevel.critical:
            logger.f(message);
          case LogLevel.none:
            logger.d(message);
        }
      }), // Debug logs
    )
        .build();

    _hubConnection!.serverTimeoutInMilliseconds = 30000;
    _hubConnection!.keepAliveIntervalInMilliseconds = 5000;

    _hubConnection!.onclose((error) {
      logger.e("❌ SignalR Connection Closed:", error: error.toString().isEmpty ? "None provided" : error.toString().isEmpty);
      _updateConnectionState(ConnectionType.disconnected);
      if (_shouldReconnect) _attemptReconnect(); // ✅ Only retry if allowed
    });

    _hubConnection!.onreconnecting((error) {
      logger.e("🔄 Reconnecting... Error:", error: error.toString().isEmpty ? "None provided" : error.toString().isEmpty);
      _updateConnectionState(ConnectionType.reconnecting);
    });

    _hubConnection!.onreconnected((connectionId) async {
      logger.i("✅ Reconnected: $connectionId");
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
      logger.e("There was an error caught while requesting support:", error: err.toString().isEmpty ? "None provided" : err.toString().isEmpty);
    }
  }
  void openChatroom(int userID, int chatroomID){
    try {
      _hubConnection!.invoke('OpenChatroom', args: [userID, chatroomID]);
    }catch(err){
      logger.e("There was an error caught while opening chatroom:", error: err.toString().isEmpty ? "None provided" : err.toString().isEmpty);
    }
  }
  void addMainTag(String tagName){
    try {
      _hubConnection!.invoke('AddMainTag', args: [tagName]);
    }catch(err){
      logger.e("There was an error caught while saving tag:", error: err.toString().isEmpty ? "None provided" : err.toString().isEmpty);
    }
  }
  void addSubTag(String tagName, String mainTagName){
    try{
      _hubConnection!.invoke('AddSubTag', args: [tagName, mainTagName]);
    }catch(err){
      logger.e("There was an error caught while saving tag:", error: err.toString());
    }
  }

  void addFAQ(String title, String description, String solution, String mainTag, String subTag){
    try{
      _hubConnection!.invoke('AddFAQ', args: [title, description, solution, mainTag, subTag]);
    }catch(err){
      logger.e("There was an error caught while saving tag:", error: err.toString());
    }
  }
  void joinChatroom(int userID, int chatroomID){
    try{
      _hubConnection!.invoke('JoinChatroom', args: [userID, chatroomID]);
    }catch(err){
      logger.e("There was an error caught while saving tag:", error: err.toString());
    }
  }

  void sendMessage(int userID, int chatroomID, String messageContent) {
    try{
      _hubConnection!.invoke('SendMessage', args: [userID, chatroomID, messageContent]);
    }catch(err){
      logger.e("There was an error caught while sending message:", error: err.toString().isEmpty ? "None provided" : err.toString().isEmpty);
    }
  }
  void sendSeen(int userID, int chatroomID){
    try{
      _hubConnection!.invoke('UserSeen', args: [userID, chatroomID]);
    }catch(err){
      logger.e("There was an error caught while sending message:", error: err.toString().isEmpty ? "None provided" : err.toString().isEmpty);
    }
  }
  /// Sets up SignalR event handlers
  void _setupEventHandlers() {

    _hubConnection!.on('MaximumChatroom', (arguments){
      onMaximumChatroom?.call();
      notifyListeners();
    });

    _hubConnection!.on('ExistingTag', (arguments){
      onExistingTag?.call();
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
        chatroom.messages!.sort((a, b) => b.createdAt.compareTo(a.createdAt!));

        onChatroomUpdate?.call(chatroom);
      }
      notifyListeners();
    });

    _hubConnection!.on('StaffJoined', (arguments){
      if(arguments != null){
        onStaffJoined?.call(User.fromJson(arguments[0]['user']), Chatroom.fromJson(arguments[0]['chatroom']));
        notifyListeners();
      }
    });
    _hubConnection!.on('TicketUpdate', (arguments) {
      if(arguments != null){
        onTicketUpdate?.call(Ticket.fromJson(arguments[0]['ticket']));
        notifyListeners();
      }
    });
    _hubConnection!.on('TicketClosed', (arguments) {
      if(arguments != null){

        notifyListeners();
      }
    });

    _hubConnection!.on('ReceiveMessage', (arguments){
      if(arguments != null) {

        onReceiveMessage?.call(Message.fromJson(arguments[0]['message']), Chatroom.fromJson(arguments[0]['chatroom']));

        notifyListeners();
      }
    });

    _hubConnection!.on('ReceiveSupport', (arguments) async {
      if(arguments != null){
        await onChatroomUpdate?.call(Chatroom.fromJson(arguments[0]['chatroom']));
        await onReceiveSupport?.call(Chatroom.fromJson(arguments[0]['chatroom']));
        notifyListeners();
      }
    });

    _hubConnection!.on('FAQUpdate', (arguments){
      if(arguments != null){
        List<FAQ> updatedFAQs =
        (arguments[0]['faq'] as List).map((faq) => FAQ.fromJson(faq)).toList();


        onFAQUpdate?.call(updatedFAQs);
        notifyListeners();
      }
    });
    _hubConnection!.on('ChatroomUpdate', (arguments) {
      if(arguments != null){
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
        logger.i("🔹 Updated Tags: ${updatedTags.length}");

        onTagUpdate?.call(updatedTags);
      }
    });
    _hubConnection!.on('Online', (arguments) {
      logger.i("🔔 SignalR Event: Online Received!");

      if (arguments != null) {
        List<MainTag> updatedTags =
        (arguments[0]['tags'] as List).map((tag) => MainTag.fromJson(tag)).toList();

        List<FAQ> updatedFAQs =
        (arguments[0]['faq'] as List).map((faq) => FAQ.fromJson(faq)).toList();

        List<Chatroom> updatedChatrooms =
        (arguments[0]['chatrooms'] as List).map((chatroom) => Chatroom.fromJson(chatroom)).toList();

        List<Ticket> updatedTickets =
        (arguments[0]['tickets'] as List).map((ticket) => Ticket.fromJson(ticket)).toList();

        List<String> updatedStatus =
        (arguments[0]['status'] as List).map((status) => status.toString()).toList();

        logger.i("🔹 Updated Tags: ${updatedTags.length}\n"
            "🔹 Updated FAQs: ${updatedFAQs.length}\n"
            "🔹 Updated Chatrooms: ${updatedChatrooms.length}\n"
            "🔹 Updated Tickets: ${updatedTickets.length}\n"
            "🔹 Updated Status: ${updatedStatus.length}"
        );
        onTagUpdate?.call(updatedTags);
        onFAQUpdate?.call(updatedFAQs);
        onTicketsUpdate?.call(updatedTickets);
        onStatusUpdate?.call(updatedStatus);
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
      await _hubConnection!.start();  // ❌ If the old tab is using the same user ID, it might get disconnected
      logger.i("✅ SignalR Connected!");
      _updateConnectionState(ConnectionType.connected);
      onConnected?.call();

      logger.i("🔄 Invoking Online Event...");
      var userSession = Hive.box<HiveSession>('sessionBox').get('user');
      await _hubConnection!.invoke("Online", args: [userSession!.user.userID, userSession!.user.role]);
    } catch (e) {
      logger.e("❌ Error connecting to SignalR:", error: e.toString());
      _updateConnectionState(ConnectionType.disconnected);
      if (_shouldReconnect) _attemptReconnect();
    }
  }

  /// Attempt to reconnect with exponential backoff
  Future<void> _attemptReconnect() async {
    if (!_shouldReconnect || _connectionState == ConnectionType.connected) return;

    _retryCount++;
    int delay = (5 * _retryCount).clamp(5, 30); // Delay increases but max 30 sec
    logger.i("🕐 Retrying in $delay seconds... (Attempt: $_retryCount)");

    await Future.delayed(Duration(seconds: delay));
    await startConnection();
  }

  /// Manually trigger reconnection
  Future<void> reconnect() async {
    logger.i("🔁 Manual Reconnect Triggered...");
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
