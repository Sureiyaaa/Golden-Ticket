import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:provider/provider.dart';

class FaqSuggestionTab extends StatefulWidget {
  final HiveSession session;
  FaqSuggestionTab({super.key, required this.session});

  @override
  State<FaqSuggestionTab> createState() => _FaqSuggestionTabState();
}

class _FaqSuggestionTabState extends State<FaqSuggestionTab> {
  List<MapEntry<String, int>> topSuggestions = [];
  List<MapEntry<String, int>> topRequested = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dataManager = Provider.of<DataManager>(context);
    _processData(dataManager);
  }

  void _processData(DataManager dataManager) {
    final tickets = dataManager.tickets;
    final faqs = dataManager.faqs;

    final existingFaqTags = faqs
        .map((f) => '${f.mainTag?.tagName}-${f.subTag?.subTagName}')
        .toSet();

    final tagPairs = <String, int>{};
    for (var ticket in tickets) {
      if (ticket.mainTag != null && ticket.subTag != null) {
        final key = '${ticket.mainTag?.tagName}-${ticket.subTag?.subTagName}';
        tagPairs[key] = (tagPairs[key] ?? 0) + 1;
      }
    }

    final suggestions = tagPairs.entries
        .where(
            (entry) => !existingFaqTags.contains(entry.key) && entry.value == 5)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final requested = tagPairs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      topSuggestions =
          suggestions; // no need to take(5) since you're filtering by weight == 5
      topRequested = requested.take(10).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(builder: (context, dataManager, child) {
      return Scaffold(
        appBar: AppBar(title: const Text('FAQ Suggestions')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text("📌 Suggested FAQs (Not Yet Created)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...topSuggestions.map((entry) {
                final parts = entry.key.split('-');
                return Card(
                  color: Colors.blue[50],
                  child: ListTile(
                    title: Text("Main Tag: ${parts[0]}"),
                    subtitle: Text("Subtag: ${parts[1]}"),
                    trailing: Text("Requests: ${entry.value}"),
                  ),
                );
              }),
              const SizedBox(height: 24),
              const Text("🔥 Most Requested Tags",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...topRequested.map((entry) {
                final parts = entry.key.split('-');
                return ListTile(
                  leading: const Icon(Icons.label_important),
                  title: Text("Main Tag: ${parts[0]}"),
                  subtitle: Text("Subtag: ${parts[1]}"),
                  trailing: Text("Count: ${entry.value}"),
                );
              }),
            ],
          ),
        ),
      );
    });
  }
}
