class Chatroom {
  final String chatroomID;
  final String chatroomName;
  final String ticketID;
  final Map<String, dynamic> ticketObject;
  final String ticketTitle;
  final String ticketDescription;
  final String openerName;
  final String ticketStatus;

  Chatroom({
    required this.chatroomID,
    required this.chatroomName,
    required this.ticketID,
    required this.ticketObject,
    required this.ticketTitle,
    required this.ticketDescription,
    required this.openerName,
    required this.ticketStatus,
  });

  /// Dummy chatroom for testing
  static Chatroom dummy() {
    return Chatroom(
      chatroomID: "chat123",
      chatroomName: "Support Chat",
      ticketID: "ticket456",
      ticketObject: {
        "priority": "High",
        "createdAt": DateTime.now().toString(),
      },
      ticketTitle: "Login Issue",
      ticketDescription: "User unable to log in due to authentication error.",
      openerName: "John Doe",
      ticketStatus: "Open",
    );
  }
}
