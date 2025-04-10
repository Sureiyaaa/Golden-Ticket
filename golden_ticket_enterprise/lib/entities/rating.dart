
import 'package:golden_ticket_enterprise/entities/chatroom.dart';

class Rating {
  final Chatroom chatroom;
  final int score;
  final String? feedback;
  final DateTime createdAt;
  Rating({ required this.chatroom, required this.score, required this.feedback, required this.createdAt});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      chatroom: Chatroom.fromJson(json['chatroom']),
      score: json['score'],
      feedback: json['feedback'] ?? 'None Provided',
      createdAt: DateTime.parse(json['createdAt'])
    );
  }

}