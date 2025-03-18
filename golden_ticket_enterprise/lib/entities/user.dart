
class User {
  int userID;
  String username;
  String firstName;
  String middleInitial;
  String lastName;
  DateTime? lastOnlineAt;

  User({required this.userID, required this.username, required this.firstName, required this.middleInitial, required this.lastName, this.lastOnlineAt});

  factory User.fromJson(Map<String, dynamic> json) {
    dynamic userData = json;
    return User(
        userID: userData['userID'],
        username: userData['username'],
        firstName: userData['firstName'],
        middleInitial: userData['middleInitial'],
        lastName: userData['lastName'],
        lastOnlineAt: userData['lastOnlineAt']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'username': username,
      'firstName': firstName,
      'middleInitial': middleInitial,
      'lastName': lastName,
      'lastOnlineAt': lastOnlineAt
    };
  }

}