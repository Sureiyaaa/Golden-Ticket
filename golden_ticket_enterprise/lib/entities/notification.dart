
class Notification {
  final int notificationID;
  String title;
  String message;
  String notificationType;
  bool isRead;
  final DateTime createdAt;
  Notification({ required this.notificationID, required this.title, required this.message, required this.notificationType, required this.isRead, required this.createdAt});

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
        notificationID: json['notificationID'],
        title: json['title'],
        message: json['description'],
        notificationType: json['notificationType'],
        isRead: json['isRead'],
        createdAt: DateTime.parse(json['createdAt'])
    );
  }

}