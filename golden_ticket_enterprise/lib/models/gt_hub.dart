import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:signalr_core/signalr_core.dart';

class SignalRService with ChangeNotifier {
  HubConnection? _hubConnection;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  final String serverUrl = "http://${kBaseURL}/${kGTHub}"; // Change this

  SignalRService() {
    _initializeConnection();
  }

  /// Initializes the SignalR connection
  Future<void> _initializeConnection() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl, HttpConnectionOptions(
      logging: (level, message) => print(message), // Debug logs
    ))
        .build();
    _hubConnection!.serverTimeoutInMilliseconds = 30000;
    _hubConnection!.keepAliveIntervalInMilliseconds = 5000;
    _hubConnection!.onclose((error) {
      print("SignalR Connection Closed: $error");
      _isConnected = false;
      notifyListeners();
      // Try to reconnect on failure
    });

    // Listen to events from the server
    _hubConnection!.on('ReceiveMessage', (arguments) {
      print("Message Received: ${arguments![0]}");
      notifyListeners(); // Notify UI to update if needed
    });

    _hubConnection!.on('UserOnline', (arguments) {
      print("User Online: ${arguments![0]}");
      notifyListeners();
    });

    await startConnection();
  }

  /// Starts the SignalR connection
  Future<void> startConnection() async {
    try {
      await _hubConnection!.start();
      _hubConnection!.serverTimeoutInMilliseconds = 30000;
      _hubConnection!.keepAliveIntervalInMilliseconds = 5000;
      print("SignalR Connected");
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      print("Error connecting to SignalR: $e");
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Reconnect with delay
  Future<void> _reconnect() async {
    await Future.delayed(Duration(seconds: 5));
    await startConnection();
  }

  /// Send a message
  Future<void> sendMessage(String message) async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.connected) {
      await _hubConnection!.invoke('SendMessage', args: [message]);
    }
  }
  Future<void> stopConnection()async {
    await _hubConnection?.stop();
  }
  /// Dispose the connection
  @override
  void dispose() {
    super.dispose();
  }
}
