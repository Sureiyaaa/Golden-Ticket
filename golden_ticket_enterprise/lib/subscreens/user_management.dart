  import 'package:flutter/material.dart';
  import 'package:golden_ticket_enterprise/entities/user.dart';
  import 'package:golden_ticket_enterprise/models/data_manager.dart';
  import 'package:golden_ticket_enterprise/models/hive_session.dart';
  import 'package:golden_ticket_enterprise/widgets/add_user_widget.dart';
  import 'package:golden_ticket_enterprise/widgets/edit_user_widget.dart';
  import 'package:provider/provider.dart';

  class UserManagementPage extends StatelessWidget {
    final HiveSession? session;

    UserManagementPage({super.key, required this.session});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text('User Management')),
        body: Consumer<DataManager>(
          builder: (context, dataManager, child) {
            // Fetch the users by role
            List<User> admins = dataManager.getAdmins();
            List<User> agents = dataManager.getAgents();
            List<User> employees = dataManager.getEmployees();

            return ListView(
              children: [
                // Pass context down here 👇
                _buildUserSection(context, 'Admin', admins),
                _buildUserSection(context, 'Staff/Agent', agents),
                _buildUserSection(context, 'Employees', employees),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "add_user",
          onPressed: () {
            showDialog(context: context, builder: (context) => AddUserWidget());
          },
          child: Icon(Icons.person_add),
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
        ),
      );
    }

    // Accept context here 👇
    Widget _buildUserSection(BuildContext context, String title, List<User> users) {
      return ExpansionTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          ...users.map((user) {
            return Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text('${user.firstName} ${user.middleName} ${user.lastName}'),
                subtitle: Text(user.role),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => EditUserWidget(user: user),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ],
      );
    }
  }
