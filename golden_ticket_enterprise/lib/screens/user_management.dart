import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                              context.go('/edit-user/${users[index]['email']}');
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
        onPressed: () {
        },
        child: Icon(Icons.person_add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
