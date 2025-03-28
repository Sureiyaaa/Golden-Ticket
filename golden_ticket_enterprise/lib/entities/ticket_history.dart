
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/sub_tag.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';

class TicketHistory {
  final String action;
  final String actionMessage;
  final DateTime actionDate;

  TicketHistory({ required this.action, required this.actionMessage, required this.actionDate});

  factory TicketHistory.fromJson(Map<String, dynamic> json) {
    return TicketHistory(
      action: json['action'] ?? "No action provided",
      actionMessage: json['actionMessage'] ?? "No message provided",
      actionDate: DateTime.parse(json['actionDate']),
    );
  }
}