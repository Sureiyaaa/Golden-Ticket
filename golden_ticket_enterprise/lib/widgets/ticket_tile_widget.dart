import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';

class TicketTile extends StatelessWidget {
  final String title;
  final String mainTag;
  final String? subTag;
  final VoidCallback onChatPressed;
  final VoidCallback onEditPressed;

  const TicketTile({
    Key? key,
    required this.title,
    required this.mainTag,
    this.subTag,
    required this.onChatPressed,
    required this.onEditPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {},
          hoverColor: kPrimaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(mainTag), backgroundColor: Colors.blue[100]),
                    if (subTag != null)
                      Chip(label: Text(subTag!), backgroundColor: Colors.green[100]),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.chat_bubble_outline, color: Colors.blue), onPressed: onChatPressed),
                      IconButton(icon: Icon(Icons.edit, color: Colors.orange), onPressed: onEditPressed),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
