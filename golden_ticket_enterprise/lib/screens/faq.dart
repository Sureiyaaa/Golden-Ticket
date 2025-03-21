import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';

class FAQPage extends StatefulWidget {
  final HiveSession? session;

  FAQPage({super.key, required this.session});

  @override
  State<FAQPage> createState() => _FAQPage();
}

class _FAQPage extends State<FAQPage> {
  final List<Map<String, String>> faqs = [
    {
      'question': 'How do I reset my password?',
      'answer': 'You can reset your password by going to the settings page and selecting "Reset Password".',
      'ticket': '/ticket/reset-password'
    },
    {
      'question': 'How do I contact support?',
      'answer': 'You can contact support via the "Help" section in the app or by emailing support@example.com.',
      'ticket': '/ticket/contact-support'
    },
    {
      'question': 'Where can I find my tickets?',
      'answer': 'Your tickets are available in the "My Tickets" section in the app.',
      'ticket': '/ticket/my-tickets'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: "add_faq",
        onPressed: () {

        },
        child: Icon(Icons.chat),
        backgroundColor: Colors.blue,
      ),
      appBar: AppBar(title: Text('FAQ')),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ExpansionTile(
              title: Text(faqs[index]['question']!),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(faqs[index]['answer']!),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context.go(faqs[index]['ticket']!);
                    },
                    child: Text('View Ticket Related'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
