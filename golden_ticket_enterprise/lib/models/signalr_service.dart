import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/faq.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/message.dart';
import 'package:golden_ticket_enterprise/entities/rating.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/entities/user.dart' as UserDTO;
import 'package:golden_ticket_enterprise/models/hive_session.dart' as UserSession;
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
  Function(List<String>)? onPriorityUpdate;
  Function(List<FAQ>)? onFAQUpdate;
  Function(Chatroom)? onChatroomUpdate;
  Function(List<Chatroom>)? onChatroomsUpdate;
  Function(Rating)? onRatingUpdate;
  Function(List<Rating>)? onRatingsUpdate;
  Function(List<Ticket>)? onTicketsUpdate;
  Function(Ticket)? onTicketUpdate;
  Function(List<UserDTO.User>)? onUsersUpdate;
  Function(UserDTO.User)? onUserUpdate;
  Function()? onNotificationReceive;
  Function(Chatroom)? onReceiveSupport;
  Function(List<String>)? onStatusUpdate;
  Function(int, int)? onSeenUpdate;
  Function(UserDTO.User, Chatroom)? onStaffJoined;
  Function()? onAllowMessage;
  Function()? onMaximumChatroom;
  Function()? onExistingTag;
  Function()? onAlreadyMember;
  Function()? onRegistrationError;

  ConnectionType _connectionState = ConnectionType.disconnected;
  ConnectionType get connectionState => _connectionState;

  bool get isConnected => _connectionState == ConnectionType.connected;

  final String serverUrl = "http://${kBaseURL}/${kGTHub}";
  int _retryCount = 0; // For exponential backoff
  bool _shouldReconnect = true; // ✅ Prevents reconnecting after logout


  /// Initializes the SignalR connection
  Future<void> initializeConnection(UserSession.HiveSession user) async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(
      serverUrl,
      // HttpConnectionOptions(logging: (level, message) {
      //   switch(level){
      //     case LogLevel.information:
      //         // logger.i(message);
      //       break;
      //     case LogLevel.trace:
      //       logger.t(message);
      //     case LogLevel.debug:
      //       logger.d(message);
      //     case LogLevel.warning:
      //       logger.w(message);
      //     case LogLevel.error:
      //       logger.e(message, error: "None Provided");
      //     case LogLevel.critical:
      //       logger.f(message);
      //     case LogLevel.none:
      //       logger.d(message);
      //   }
      // }), // Debug logs
    )
        .build();

    _hubConnection!.serverTimeoutInMilliseconds = 30000;
    _hubConnection!.keepAliveIntervalInMilliseconds = 5000;

    _hubConnection!.onclose((error) {
      logger.e("❌ SignalR Connection Closed:", error: error.toString().isEmpty ? "None provided" : error.toString());
      _updateConnectionState(ConnectionType.disconnected);
      if (_shouldReconnect) _attemptReconnect(); // ✅ Only retry if allowed
    });

    _hubConnection!.onreconnecting((error) {
      logger.e("🔄 Reconnecting... Error:", error: error.toString().isEmpty ? "None provided" : error.toString());
      _updateConnectionState(ConnectionType.reconnecting);
    });

    _hubConnection!.onreconnected((connectionId) async {
      logger.i("✅ Reconnected: $connectionId");
      _retryCount = 0; // Reset retry count on successful reconnection
      _updateConnectionState(ConnectionType.connected);
      await _hubConnection!.invoke("Online", args: [user.user.userID, user.user.role]);
    });

    _setupEventHandlers();

    await startConnection();
  }

  void requestChat(int userID) async {
      await _hubConnection!.invoke('RequestChat', args: [userID]).catchError((err) {
        logger.e("There was an error caught while sending a message", error: err.toString().isEmpty ? "None provided" : err.toString());
      });
  }
  void openChatroom(int userID, int chatroomID) async {
      await _hubConnection!.invoke('OpenChatroom', args: [userID, chatroomID]).catchError((err) {
        logger.e("There was an error caught while opening chatroom", error: err.toString().isEmpty ? "None provided" : err.toString());
      });
  }
  void addMainTag(String tagName) async {
      await _hubConnection!.invoke('AddMainTag', args: [tagName]).catchError((err) {
        logger.e("There was an error caught while saving main tag", error: err.toString().isEmpty ? "None provided" : err.toString());
      });
  }

  void updateTicket(int ticketID, String title, String status, String priority, String? mainTag, String? subTag, int? assignedID) async {
      await _hubConnection!.invoke('UpdateTicket', args: [
        ticketID,
        title,
        status,
        priority,
        mainTag?.isEmpty == true ? null : mainTag,  // Ensure null instead of empty string
        subTag?.isEmpty == true ? null : subTag,    // Ensure null instead of empty string
        assignedID == 0 ? null : assignedID         // Ensure null instead of 0
      ]).catchError((err) {
        logger.e("There was an error caught while updating ticket", error: err.toString().isEmpty ? "None provided" : err.toString().isEmpty);
      });
  }

  void updateFAQ(int faqID, String faqTitle, String faqDescription, String faqSolution, String? mainTag, String? subTag, bool faqArchive) async {
      await _hubConnection!.invoke('UpdateFAQ', args: [
        faqID,
        faqTitle,
        faqDescription,
        faqSolution,   // Ensure null instead of empty string
        mainTag?.isEmpty == true ? null : mainTag,  // Ensure null instead of empty string
        subTag?.isEmpty == true ? null : subTag,
        faqArchive
      ]).catchError((err) {
        logger.e("There was an error caught while updating FAQ", error: err.toString().isEmpty ? "None provided" : err.toString());
      });
  }


  void addSubTag(String tagName, String mainTagName)async{
      await _hubConnection!.invoke('AddSubTag', args: [tagName, mainTagName]).catchError((err) {
        logger.e("There was an error caught while sending a message", error: err.toString().isEmpty ? "None provided" : err.toString());
      });
  }
  void addRating(int chatroomID, int score, String? feedback)async{
    await _hubConnection!.invoke('AddRating', args: [chatroomID, score, feedback]).catchError((err) {
      logger.e("There was an error caught while saving rating", error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void addFAQ(String title, String description, String solution, String mainTag, String subTag) async{
      await _hubConnection!.invoke('AddFAQ', args: [title, description, solution, mainTag, subTag]).catchError((err) {
        logger.e("There was an error caught while adding FAQ", error: err.toString().isEmpty ? "None provided" : err.toString());
      });
  }
  void joinChatroom(int userID, int chatroomID) async {
      await _hubConnection!.invoke('JoinChatroom', args: [userID, chatroomID]).catchError((err) {
        logger.e("There was an error caught while joining chatroom", error: err.toString().isEmpty ? "None provided" : err.toString());
      });
  }

  void updateUser(int userID, String? username, String? password, String? firstName, String? middleName, String? lastName, String? role, List<String?> assignedTags) async {
      await _hubConnection!.invoke('UpdateUser', args: [userID, username, firstName, middleName, lastName, role, assignedTags, password]).catchError((err) {
        logger.e("There was an error caught while updating user", error: err.toString().isEmpty ? "None provided" : err.toString());
      });
  }

  void addUser(String username, String password, String firstName, String? middleName, String lastName, String role, List<String> assignedTags) async {
      await _hubConnection!.invoke('AddUser', args: [username, password, firstName, middleName,lastName, role, assignedTags]).catchError((err) {
        logger.e("There was an error caught while Add User", error: err.toString().isEmpty ? "None provided" : err.toString());
      });
  }


  void reopenChatroom(int userID, int chatroomID) async {
      await _hubConnection!.invoke('ReopenChatroom', args: [userID, chatroomID]).catchError((err) {
        logger.e("There was an error caught while Reopen Chatroom", error: err.toString().isEmpty ? "None provided" : err.toString());
      });

  }

  void sendMessage(int userID, int chatroomID, String messageContent) async {
    await _hubConnection!.invoke('SendMessage', args: [userID, chatroomID, messageContent]).catchError((err) {
      logger.e("There was an error caught while sending a message", error: err.toString());
    });
  }
  void sendSeen(int userID, int chatroomID) async {
      await _hubConnection!.invoke('UserSeen', args: [userID, chatroomID]).catchError((err) {
        logger.e("There was an error caught while sending user seen", error: err.toString());
      });
  }
  /// Sets up SignalR event handlers
  void _setupEventHandlers() async {

    _hubConnection!.on('MaximumChatroom', (arguments){
      onMaximumChatroom?.call();
      notifyListeners();
    });

    _hubConnection!.on('AlreadyMember', (arguments){
      onAlreadyMember?.call();
      notifyListeners();
    });

    _hubConnection!.on('ExistingTag', (arguments){
      onExistingTag?.call();
      notifyListeners();
    });

    _hubConnection!.on('UserExist', (arguments){
      onRegistrationError?.call();
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
        onStaffJoined?.call(UserDTO.User.fromJson(arguments[0]['user']), Chatroom.fromJson(arguments[0]['chatroom']));
        notifyListeners();
      }
    });

    _hubConnection!.on('RatingUpdate', (arguments) {
      if(arguments != null){
        onRatingUpdate?.call(Rating.fromJson(arguments[0]['ticket']));
        notifyListeners();
      }
    });


    _hubConnection!.on('RatingsUpdate', (arguments) {
      if(arguments != null){
        List<Rating> updatedRatings =
        (arguments[0]['rating'] as List).map((rating) => Rating.fromJson(rating)).toList();

        onRatingsUpdate?.call(updatedRatings);
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

    _hubConnection!.on('UserUpdate', (arguments){
      if(arguments != null) {

        UserDTO.User user = UserDTO.User.fromJson(arguments[0]['user']);
        onUserUpdate?.call(user);


        var userSession = Hive.box<UserSession.HiveSession>('sessionBox').get('user')!.user;

        if(user.userID == userSession.userID){
          userSession.username = user.username;
          userSession.firstName = user.firstName;
          userSession.middleName = user.middleName ?? "";
          userSession.lastName = user.lastName;
          userSession.role = user.role;
        }

        notifyListeners();
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

        List<UserDTO.User> updatedUsers =
        (arguments[0]['users'] as List).map((user) => UserDTO.User.fromJson(user)).toList();

        List<String> updatedPriorities =
        (arguments[0]['priorities'] as List).map((priority) => priority.toString()).toList();

        List<Rating> updatedRatings =
        (arguments[0]['ratings'] as List).map((rating) => Rating.fromJson(rating)).toList();

        logger.i("🔹 Updated Tags: ${updatedTags.length}\n"
            "🔹 Updated FAQs: ${updatedFAQs.length}\n"
            "🔹 Updated Chatrooms: ${updatedChatrooms.length}\n"
            "🔹 Updated Tickets: ${updatedTickets.length}\n"
            "🔹 Updated Ratings: ${updatedRatings.length}\n"
            "🔹 Updated Users: ${updatedUsers.length}\n"
            "🔹 Updated Status: ${updatedStatus.length}\n"
            "🔹 Updated Priorities: ${updatedPriorities.length}"
        );
        onTagUpdate?.call(updatedTags);
        onPriorityUpdate?.call(updatedPriorities);
        onFAQUpdate?.call(updatedFAQs);
        onTicketsUpdate?.call(updatedTickets);
        onStatusUpdate?.call(updatedStatus);
        onUsersUpdate?.call(updatedUsers);
        onChatroomsUpdate?.call(updatedChatrooms);
        onRatingsUpdate?.call(updatedRatings);
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
      var userSession = Hive.box<UserSession.HiveSession>('sessionBox').get('user');
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
    if(_retryCount > 3) _shouldReconnect = false;
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
