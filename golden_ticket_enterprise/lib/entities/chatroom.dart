
import 'package:golden_ticket_enterprise/entities/Message.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';

class Chatroom {
  final int chatroomID;
  final String chatroomName;
  final User author;
  Ticket? ticket;
  List<Message>? messages = [];
  final DateTime createdAt;

  Chatroom({required this.chatroomID, required this.chatroomName, required this.author, this.ticket, required this.createdAt, this.messages});

  factory Chatroom.fromJson(Map<String, dynamic> json) {
    dynamic userData = json;

    List<Message> msgs = [];
    for(var msg in json['messages']){
      msgs.add(Message.fromJson(msg));
    }
    return Chatroom(
        chatroomID: json['chatroomID'],
        author: User.fromJson(json['author']),
        createdAt: DateTime.parse(json['createdAt']),
        chatroomName: json['chatroomName'],
        messages: msgs,
        ticket: json['ticket'] == null ? null : Ticket.fromJson(json['ticket'])
    );
  }


}