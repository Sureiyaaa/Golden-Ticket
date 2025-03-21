import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/models/gt_hub.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/screens/dashboard.dart';
import 'package:golden_ticket_enterprise/screens/faq.dart';
import 'package:golden_ticket_enterprise/screens/tickets.dart';
import 'package:golden_ticket_enterprise/screens/user_management.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HubPage extends StatefulWidget {
  final HiveSession? session;
  List<MainTag> mainTags = [];

  final SignalRService signalRService;
  HubPage({super.key, required this.session, required this.signalRService});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  int _selectedIndex = 0; // Track selected index
  bool _redirecting = false;
  late final Box<HiveSession> _sessions;

  @override
  void initState() {

    super.initState();
    // if (widget.session.user) {
    //   _redirecting = true; // Mark as redirecting to prevent build
    //   widget.signalRService.stopConnection();
    //   Future.microtask(() => context.go('/login'));
    // }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.session == null && !_redirecting) {
      _redirecting = true;
      Future.microtask(() => context.go('/error', extra: "Unauthorized Access!"));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // void _getSessionsBox() async {
  //   // check if session is still valid
  //   if (Hive.isBoxOpen('sessionBox')) {
  //     _sessions = Hive.box<HiveSession>('sessionBox');
  //
  //   } else {
  //     _sessions = await Hive.openBox<HiveSession>('sessionBox');
  //   }
  // }
  void _logout() async {
    var box = Hive.box<HiveSession>('sessionBox');
    await box.delete('user'); // Clear session
    widget.signalRService.stopConnection();
    context.go('/login'); // Navigate to login
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session == null) {
      return SizedBox.shrink(); // Prevents UI from rendering if redirecting
    }
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kPrimary,
        title: Text(_getAppBarTitle()), // Dynamic title
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: kPrimaryContainer,
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(widget.session!.user.username),
              accountEmail: Text("Dummy Email"),
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.person, size: 40),
              ),
            ),
            _buildDrawerItem(Icons.dashboard, "Dashboard", 0),
            if(widget.session?.user.role == "Admin" || widget.session?.user.role == "Staff") _buildDrawerItem(Icons.list, "Tickets", 1),
            _buildDrawerItem(Icons.question_mark, "FAQ", 2),
            if(widget.session?.user.role == "Admin") _buildDrawerItem(Icons.person_outline, "User Management", 3),
            _buildDrawerItem(Icons.settings, "Settings", 4),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardPage(session: widget.session!),
          TicketsPage(session: widget.session!), // TicketsPage is now properly integrated here
          FAQPage(session: widget.session!),
          UserManagementPage(session: widget.session!)

        ],
      ),
    );
  }

  /// **Dynamic AppBar Title**
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return "Dashboard";
      case 1:
        return "Tickets";
      case 2:
        return "FAQ";
      case 3:
        return "User Management";
      case 4:
        return "Settings";
      default:
        return "Dashboard";
    }
  }

  /// **Drawer Item Builder with Highlighting**
  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? Colors.blue : Colors.black),
      title: Text(title, style: TextStyle(color: _selectedIndex == index ? Colors.blue : Colors.black)),
      tileColor: _selectedIndex == index ? Colors.blue.withOpacity(0.2) : null,
      onTap: () => _onDrawerItemTapped(index),
    );
  }

  /// **Settings View**
  Widget _buildSettingsView() {
    return Center(
      child: Text("This is the Settings Page.", style: TextStyle(fontSize: 20)),
    );
  }
}
