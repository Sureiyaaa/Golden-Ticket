import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/notification.dart'
    as notifClass;
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/screens/connectionstate.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/screens/notification_page.dart';
import 'package:golden_ticket_enterprise/widgets/notification_tile_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class HubPage extends StatefulWidget {
  final HiveSession? session;
  final StatefulNavigationShell child;
  final DataManager dataManager;
  List<MainTag> mainTags = [];
  HubPage(
      {Key? key,
      required this.session,
      required this.child,
      required this.dataManager})
      : super(key: key);

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  late DataManager dm;
  late int _selectedIndex; // Track selected index
  bool _isInitialized = false;

  @override
  void initState() {
    _selectedIndex = widget.child.currentIndex;
    super.initState();
    dm = Provider.of<DataManager>(context, listen: false);

    dm.signalRService.addOnReceiveSupportListener(_handleReceiveSupport);
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

  void _onDrawerItemTapped(int index) {
    print("Selected Index: $_selectedIndex");
    print("Navigating to tab: $index");
    setState(() {
      _selectedIndex = index;
    });
    widget.child
        .goBranch(index, initialLocation: index == widget.child.currentIndex);
  }

  void _handleReceiveSupport(Chatroom chatroom){
    context.push('/hub/chatroom/${chatroom.chatroomID}');
  }
  @override
  Widget build(BuildContext context) {
    if (widget.session == null) {
      return SizedBox.shrink(); // Prevents UI from rendering if redirecting
    }
    return Consumer<DataManager>(builder: (context, dataManager, child) {
      if (!dataManager.signalRService.isConnected) {
        return DisconnectedOverlay();
      }
      int unreadCount = dataManager.notifications.where((notif) => !notif.isRead).length;

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
              PopupMenuButton(
                icon: Stack(clipBehavior: Clip.none, children: [
                  Icon(Icons.notifications),
                  if (unreadCount > 0)
                    Positioned(
                      right: -5,
                      top: -8,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(
                          unreadCount.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ]),
                tooltip: "Notifications",
                itemBuilder: (context) {
                  List<PopupMenuEntry> items = [];

                  items.add(
                    PopupMenuItem(
                      enabled: false,
                      padding: EdgeInsets.zero,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 200, // Minimum height
                          maxHeight: 400, // Maximum height to prevent overflow
                        ),
                        child: dataManager.notifications.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text('No notifications'),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: dataManager.notifications.map((notif) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 10),
                                      child: InkWell(
                                        onTap: () {},
                                        child: NotificationTile(
                                            notification: notif),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                    ),
                  );

                  items.add(const PopupMenuDivider());

                  items.add(
                    PopupMenuItem(
                      enabled: false,
                      child: Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotificationsPage(
                                    notifications: dataManager.notifications),
                              ),
                            );
                          },
                          child: Text('See all notifications'),
                        ),
                      ),
                    ),
                  );

                  return items;
                },
              ),
              IconButton(
                icon: Icon(Icons.logout),
                tooltip: "Logout",
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
                if (widget.session?.user.role == "Admin" ||
                    widget.session?.user.role == "Staff")
                  _buildDrawerItem(Icons.list, "Tickets", 2),
                _buildDrawerItem(Icons.question_mark, "FAQ", 3),
                if (widget.session?.user.role != "Employee")
                  _buildDrawerItem(Icons.show_chart, "Reports", 4),
                if (widget.session?.user.role == "Admin")
                  _buildDrawerItem(Icons.person_outline, "User Management", 5),
                if (widget.session?.user.role == "Admin")
                  _buildDrawerItem(Icons.settings, "Settings", 6),
              ],
            ),
          ),
          body: widget.child);
    });
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
        return "Reports";
      case 5:
        return "User Management";
      case 6:
        return "Settings";
      default:
        return "Dashboard";
    }
  }

  /// **Drawer Item Builder with Highlighting**
  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon,
          color: _selectedIndex == index ? Colors.blue : Colors.black),
      title: Text(title,
          style: TextStyle(
              color: _selectedIndex == index ? Colors.blue : Colors.black)),
      tileColor: _selectedIndex == index ? Colors.blue.withOpacity(0.2) : null,
      onTap: () => _onDrawerItemTapped(index),
    );
  }
}
