import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/faq.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:golden_ticket_enterprise/models/class_enums.dart';

class SignalRService with ChangeNotifier {
  HubConnection? _hubConnection;
  VoidCallback? onConnected;

  Function(List<MainTag>)? onTagUpdate;
  Function(List<FAQ>)? onFAQUpdate;
  Function(List<MainTag>)? onTicketUpdate;

  ConnectionType _connectionState = ConnectionType.disconnected;
  ConnectionType get connectionState => _connectionState;
  bool get isConnected => _connectionState == ConnectionType.connected;

  final String serverUrl = "http://${kBaseURL}/${kGTHub}";
  int _retryCount = 0; // For exponential backoff
  bool _shouldReconnect = true; // ✅ Prevents reconnecting after logout


  /// Initializes the SignalR connection
  Future<void> initializeConnection() async {
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

    _hubConnection!.onreconnected((connectionId) {
      print("✅ Reconnected: $connectionId");
      _retryCount = 0; // Reset retry count on successful reconnection
      _updateConnectionState(ConnectionType.connected);
    });

    _setupEventHandlers();

    await startConnection();
  }

  /// Sets up SignalR event handlers
  void _setupEventHandlers() {
    _hubConnection!.on('ReceiveMessage', (arguments) {
      print("📩 Message Received: ${arguments![0]}");
      notifyListeners();
    });

    _hubConnection!.on('Online', (arguments) {
      print("🔔 SignalR Event: Online Received!");
      if (arguments != null) {
        List<MainTag> updatedTags =
        (arguments[0]['tags'] as List).map((tag) => MainTag.fromJson(tag)).toList();

        List<FAQ> updatedFAQs =
        (arguments[0]['faq'] as List).map((faq) => FAQ.fromJson(faq)).toList();

        print("🔹 Updated Tags: ${updatedTags.length}");
        print("🔹 Updated FAQs: ${updatedFAQs.length}");

        onTagUpdate?.call(updatedTags);
        onFAQUpdate?.call(updatedFAQs);
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
      await _hubConnection!.invoke("Online", args: []);
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
    _shouldReconnect = false; // Prevent auto-reconnect
    await _hubConnection?.stop();
    print("❌ SignalR disconnected for this tab.");
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
