import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/sub_tag.dart';

class ApiKey {
  final int apiKeyID;
  String apiKey;
  String? note;
  DateTime? lastRateLimit;
  ApiKey({ required this.apiKeyID, required this.apiKey, required this.note, required this.lastRateLimit });

  factory ApiKey.fromJson(Map<String, dynamic> json) {
    return ApiKey(
      apiKeyID: json['apiKeyID'],
      apiKey: json['apiKey'],
      note: json['notes'] ?? 'No note provided.',
      lastRateLimit: json['lastRateLimit'] == null ? null: DateTime.parse(json['lastRateLimit'].toString())
    );
  }
}