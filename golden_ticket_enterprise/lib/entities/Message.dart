
import 'package:golden_ticket_enterprise/entities/user.dart';

class Message {
  final int messageID;
  final String messageContent;
  final User sender;
  final DateTime createdAt;
  Message({required this.messageID, required this.sender, required this.messageContent, required this.createdAt});

  factory Message.fromJson(Map<String, dynamic> json) {
    dynamic userData = json;
    return Message(
        messageID: json['messageID'],
        messageContent: json['messageContent'],
        sender: User.fromJson(json['sender']),
        createdAt: DateTime.parse(json['createdAt'])
    );
  }

}