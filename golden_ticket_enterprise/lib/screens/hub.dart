import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/screens/connectionstate.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class HubPage extends StatefulWidget {
  final HiveSession? session;
  final StatefulNavigationShell child;
  final DataManager dataManager;
  List<MainTag> mainTags = [];
  HubPage({Key? key, required this.session, required this.child, required this.dataManager}) : super(key: key);

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage>{
  late int _selectedIndex; // Track selected index
  bool _isInitialized = false;
  @override
  void initState(){
    _selectedIndex = widget.child.currentIndex;
    super.initState();
  }
  @override
  void didChangeDependencies() {

    if (!_isInitialized && !widget.dataManager.signalRService.isConnected) {
      log("HubPage: Initializing SignalR Connection...");
      widget.dataManager.signalRService.initializeConnection(widget.session!);
      _isInitialized = true;
    }
    super.didChangeDependencies();
  }



  @override
  void dispose() {
    log("HubPage disposed: $this");
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


  void _onDrawerItemTapped(int index) {
    print("Selected Index: $_selectedIndex");
    print("Navigating to tab: $index");
    setState(() {
      _selectedIndex = index;
    });
    widget.child.goBranch(index, initialLocation: index == widget.child.currentIndex);
  }


  @override
  Widget build(BuildContext context) {
    if (widget.session == null) {
      return SizedBox.shrink(); // Prevents UI from rendering if redirecting
    }
    return Consumer<DataManager>(
        builder: (context, dataManager, child) {
          if (!dataManager.signalRService.isConnected) {
            return DisconnectedOverlay();
          }
          void _logout() async {
            var box = Hive.box<HiveSession>('sessionBox');
            context.go('/login');
            await box.delete('user'); // Clear session
            await dataManager.closeConnection();
          }
          return Scaffold(
            backgroundColor: kSurface,
            appBar: AppBar(
              backgroundColor: kPrimary,
              title: Text(_getAppBarTitle()), // Dynamic title
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: (){},
                ),
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
                    decoration: BoxDecoration(color: kPrimary),
                    currentAccountPicture: CircleAvatar(
                      child: Icon(Icons.person, size: 40),
                    ),
                  ),
                  _buildDrawerItem(Icons.dashboard, "Dashboard", 0),
                  _buildDrawerItem(Icons.message_outlined, "Chatrooms", 1),
                  if(widget.session?.user.role == "Admin" || widget.session?.user.role == "Staff") _buildDrawerItem(Icons.list, "Tickets", 2),
                  _buildDrawerItem(Icons.question_mark, "FAQ", 3),
                  if(widget.session?.user.role == "Admin") _buildDrawerItem(Icons.person_outline, "User Management", 4),
                  if(widget.session?.user.role == "Admin") _buildDrawerItem(Icons.settings, "Settings", 5),
                ],
              ),
            ),
            body: widget.child
          );
        }
    );

  }

  /// **Dynamic AppBar Title**
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return "Dashboard";
      case 1:
        return "Chatroom";
      case 2:
        return "Tickets";
      case 3:
        return "FAQ";
      case 4:
        return "User Management";
      case 5:
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
}
