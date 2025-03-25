
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/sub_tag.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';

class Ticket {
  final int ticketID;
  final String ticketTitle;
  final User author;
  User? assigned;
  final String status;
  final MainTag mainTag;
  SubTag? subTag;
  final DateTime createdAt;
  DateTime? deadlineAt;

  Ticket({ required this.ticketID, required this.ticketTitle, required this.author, this.assigned, required this.status, required this.mainTag, this.subTag, required this.createdAt, this.deadlineAt});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketID: json['ticketID'],
      ticketTitle: json['ticketTitle'],
      mainTag: MainTag.fromJson(json['mainTag']),
      subTag: json['subTag'] == null  ? null : SubTag.fromJson(json['subTag']),
      author: User.fromJson(json['author']),
      status: json['status'],
      assigned: json['assignedID'] == null ? null : User.fromJson(json['assigned']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

}