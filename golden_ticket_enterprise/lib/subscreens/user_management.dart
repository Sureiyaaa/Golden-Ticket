import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/widgets/add_user_widget.dart';
import 'package:golden_ticket_enterprise/widgets/user_edit_widget.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';

class UserManagementPage extends StatefulWidget {
  final HiveSession? session;

  UserManagementPage({super.key, required this.session});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final List<Map<String, String>> users = [
    {'name': 'John Doe', 'email': 'john.doe@example.com', 'role': 'Admin'},
    {'name': 'Jane Smith', 'email': 'jane.smith@example.com', 'role': 'User'},
    {'name': 'Mike Johnson', 'email': 'mike.johnson@example.com', 'role': 'Support'},
  ];

  void _openAdminPopup({String? name, String? email, String? role, int? index}) {
    showDialog(
      context: context,
      builder: (context) => AddUserWidget(
        adminName: name,
        adminEmail: email,
        adminRole: role,
        onSave: (newName, newEmail, newRole) {
          setState(() {
            if (index != null) {
              users[index] = {"name": newName, "email": newEmail, "role": newRole};
            } else {
              users.add({"name": newName, "email": newEmail, "role": newRole});
            }
          });
        },
      ),
    );
  }

  void _openEditAdminPopup(int index) {
    var user = users[index];
    showDialog(
      context: context,
      builder: (context) => EditUserPopup(
        adminName: user["name"]!,
        adminEmail: user["email"]!,
        adminRole: user["role"]!,
        onSave: (newName, newEmail, newRole) {
          setState(() {
            users[index] = {"name": newName, "email": newEmail, "role": newRole};
          });
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Management')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ExpansionTile(
              title: Text(users[index]['name']!),
              subtitle: Text(users[index]['email']!),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${users[index]['role']!}', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _openEditAdminPopup(index);
                            },
                            child: Text('Edit'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                users.removeAt(index);
                              });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: Text('Delete', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add_user",
        onPressed: () => _openAdminPopup(),
        child: Icon(Icons.person_add),
        foregroundColor: kTertiary,
        backgroundColor: kPrimary,
      ),
    );
  }
}
