
class User {
  final int userID;
  final String username;
  final String firstName;
  String? middleName = "";
  final String lastName;
  final String role;
  String? email = "None Provided";
  String? phoneNumber = "None Provided";
  final DateTime? lastOnlineAt;

  User({required this.userID, required this.username, required this.firstName, this.middleName, required this.lastName, required this.role, this.lastOnlineAt, this.email, this.phoneNumber});

  factory User.fromJson(Map<String, dynamic> json) {
    dynamic userData = json;
    return User(
        userID: userData['userID'] ?? "",
        username: userData['username'] ?? "",
        firstName: userData['firstName'] ?? "",
        middleName: userData['middleName'] ?? "",
        role: userData['role'],
        lastName: userData['lastName'] ?? "",
        lastOnlineAt: userData['lastOnlineAt'],
        email: userData['email'] ?? "None provided",
        phoneNumber: userData['phoneNumber'] ?? "None provided"
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'username': username,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'lastOnlineAt': lastOnlineAt
    };
  }

}