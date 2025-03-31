

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';

class ChatroomDetailsDrawer extends StatelessWidget {
  final Chatroom chatroom;

  const ChatroomDetailsDrawer({Key? key, required this.chatroom}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("Building ChatroomDetailsDrawer - Ticket Status: ${chatroom.ticket?.status}");

    return Drawer(
      backgroundColor: kPrimaryContainer,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: kPrimary),
            child: Text(
              '${chatroom.author.firstName} ${chatroom.author.lastName}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Created By"),
            subtitle: Text('${chatroom.author.firstName} ${chatroom.author.lastName}' ?? "Unknown"),
          ),
          ExpansionTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text("Ticket"),
            subtitle: Text('${chatroom.ticket != null ? 'Ticket ID: ${chatroom.ticket!.ticketID}': 'No Ticket' }'),
            children: [
              if(chatroom.ticket != null) ListTile(
                title: const Text("Ticket Title:"),
                subtitle: Text('${chatroom.ticket?.ticketTitle ?? "No Title Provided"}')
              ),
              if(chatroom.ticket != null && chatroom.ticket?.assigned != null) ListTile(
                  title: const Text("Assigned Agent:"),
                  subtitle: Text('${chatroom.ticket!.assigned!.firstName}')
              ),
              if(chatroom.ticket != null) ListTile(
                  title: const Text("Status:"),
                  subtitle: Chip(backgroundColor: getStatusColor(chatroom.ticket!.status),label: Text(chatroom.ticket!.status, style: TextStyle(fontWeight: FontWeight.bold, color: kSurface),))
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.people),
            title: const Text("Members"),
            subtitle: Text("${chatroom.groupMembers.length} members"),
            children: chatroom.groupMembers.map((member) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text("${member.member!.firstName} ${member.member!.lastName}"),
                subtitle: Text(TimeUtil.formatCreationDate(member.joinedAt!)),
              );
            }).toList(),
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text("Date Created"),
            subtitle: Text(TimeUtil.formatCreationDate(chatroom.createdAt.toLocal())),
          ),
        ],
      ),
    );
  }
}
