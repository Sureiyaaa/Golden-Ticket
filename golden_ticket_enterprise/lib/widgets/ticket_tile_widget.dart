import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';

class TicketTile extends StatelessWidget {
  final String title;
  final String mainTag;
  final String? subTag;
  final String status;
  final String priority;
  final String author;
  final VoidCallback onChatPressed;
  final VoidCallback onViewPressed;
  final VoidCallback onEditPressed;

  const TicketTile({
    Key? key,
    required this.title,
    required this.mainTag,
    this.subTag,
    required this.status,
    required this.priority,
    required this.author,
    required this.onChatPressed,
    required this.onViewPressed,
    required this.onEditPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onViewPressed,
        hoverColor: kPrimaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(mainTag), backgroundColor: Colors.blue[100]),
                  if (subTag != null)
                    Chip(label: Text(subTag!), backgroundColor: Colors.green[100]),
                  Chip(
                    label: Text(status, style: const TextStyle(color: Colors.white)),
                    backgroundColor: getStatusColor(status),
                  ),
                  Chip(
                    label: Text(priority, style: const TextStyle(color: Colors.white)),
                    backgroundColor: getPriorityColor(priority),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text("Author: $author", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue), onPressed: onChatPressed),
                    IconButton(icon: const Icon(Icons.visibility, color: Colors.blue), onPressed: onViewPressed),
                    IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: onEditPressed),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
