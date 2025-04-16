import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/notification.dart' as notifClass;
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/screens/connectionstate.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/widgets/selectable_notification_tile_widget.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  final List<notifClass.Notification> notifications;

  const NotificationsPage({super.key, required this.notifications});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final Set<int> _selectedNotificationIds = {};
  bool _selectionMode = false;
  String _filter = 'All';
  String _searchQuery = '';

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedNotificationIds.contains(id)) {
        _selectedNotificationIds.remove(id);
      } else {
        _selectedNotificationIds.add(id);
      }
      if (_selectedNotificationIds.isEmpty) _selectionMode = false;
    });
  }

  void _startSelection(int id) {
    setState(() {
      _selectionMode = true;
      _selectedNotificationIds.add(id);
    });
  }

  void _deleteSelected() {
    setState(() {
      widget.notifications.removeWhere((notif) =>
          _selectedNotificationIds.contains(notif.notificationID));
      _selectedNotificationIds.clear();
      _selectionMode = false;
    });
  }

  void _handleTap(notifClass.Notification notif) {
    if (_selectionMode) {
      _toggleSelection(notif.notificationID);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tapped on: ${notif.title}')),
      );
    }
  }

  List<notifClass.Notification> getFilteredNotifications() {
    return widget.notifications.where((notif) {
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Read' && notif.isRead) ||
          (_filter == 'Unread' && !notif.isRead);
      final query = _searchQuery.toLowerCase();
      final matchesSearch = notif.title.toLowerCase().contains(query) ||
          (notif.message?.toLowerCase().contains(query) ?? false) ||
          notif.notificationType.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(builder: (context, dataManager, child) {
      if (!dataManager.signalRService.isConnected) {
        return DisconnectedOverlay();
      }

      return Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          backgroundColor: kPrimary,
          title: const Text("Notifications"),
          actions: [
            if (_selectionMode)
              IconButton(
                icon: const Icon(Icons.mark_as_unread),
                onPressed:
                _selectedNotificationIds.isEmpty ? null : _deleteSelected,
              ),
            if (_selectionMode)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed:
                _selectedNotificationIds.isEmpty ? null : _deleteSelected,
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Search first (takes more space)
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search notifications...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Compact Filter
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _filter,
                          style: TextStyle(fontSize: 14, color: Colors.black),
                          items: ['All', 'Unread', 'Read'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _filter = val!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: getFilteredNotifications().isEmpty
                  ? const Center(child: Text("No notifications found"))
                  : ListView.builder(
                itemCount: getFilteredNotifications().length,
                itemBuilder: (context, index) {
                  final notif = getFilteredNotifications()[index];
                  return SelectableNotificationTile(
                    notification: notif,
                    isSelected: _selectedNotificationIds
                        .contains(notif.notificationID),
                    selectionMode: _selectionMode,
                    onTap: () => _handleTap(notif),
                    onLongPress: () => _startSelection(notif.notificationID),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
