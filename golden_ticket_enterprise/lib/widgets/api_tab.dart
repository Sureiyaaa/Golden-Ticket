import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/apikey.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';

class ApiKeysTab extends StatefulWidget {
  final DataManager dataManager;

  const ApiKeysTab({Key? key, required this.dataManager}) : super(key: key);

  @override
  State<ApiKeysTab> createState() => _ApiKeysTabState();
}

class _ApiKeysTabState extends State<ApiKeysTab> {
  void _showApiKeyDialog({ApiKey? apiKey, int? index}) {
    final keyController = TextEditingController(text: apiKey?.apiKey ?? '');
    final noteController = TextEditingController(text: apiKey?.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(apiKey == null ? "Add API Key" : "Edit API Key"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: InputDecoration(labelText: "API Key"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: "Note"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final key = keyController.text.trim();
              final note = noteController.text.trim();
              if (key.isNotEmpty) {
                setState(() {
                  if (apiKey == null) {
                    widget.dataManager.signalRService.addAPIKey(key, note);
                  } else if (index != null) {
                    widget.dataManager.signalRService.updateAPIKey(apiKey.apiKeyID, key, note);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(apiKey == null ? "Add" : "Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = widget.dataManager;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showApiKeyDialog(),
              icon: const Icon(Icons.add),
              label: const Text("Add API Key"),
            ),
          ),
          const SizedBox(height: 10),
          dataManager.apiKeys.isEmpty
              ? const Center(child: Text("No API Keys", style: TextStyle(color: Colors.grey)))
              : Expanded(
            child: ListView.builder(
              itemCount: dataManager.apiKeys.length,
              itemBuilder: (context, index) {
                final apiKey = dataManager.apiKeys[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.vpn_key),
                    title: Text(apiKey.apiKey),
                    subtitle: Text(apiKey.note ?? "No note"),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showApiKeyDialog(apiKey: apiKey, index: index);
                        } else if (value == 'delete') {
                          setState(() {
                            widget.dataManager.signalRService.deleteAPIKey(apiKey.apiKeyID);
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
