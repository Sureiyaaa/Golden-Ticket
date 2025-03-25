import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';

class SettingsPage extends StatefulWidget {
  final HiveSession? session;

  SettingsPage({super.key, required this.session});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _mainTagController = TextEditingController();
  final TextEditingController _subTagController = TextEditingController();

  String? selectedMainTag;

  void _addMainTag(DataManager dataManager) {
    String tagName = _mainTagController.text.trim();
    if (tagName.isNotEmpty) {
      // dataManager.addMainTag(MainTag(tagID: DateTime.now().millisecondsSinceEpoch, tagName: tagName));
      _mainTagController.clear();
    }
  }

  void _addSubTag(DataManager dataManager) {
    String subTagName = _subTagController.text.trim();
    if (subTagName.isNotEmpty && selectedMainTag != null) {
      MainTag? mainTag = dataManager.mainTags.firstWhere((tag) => tag.tagName == selectedMainTag, orElse: () => MainTag(tagID: -1, tagName: '', subTags: []));
      if (mainTag.tagID != -1) {
        // dataManager.addSubTag(SubTag(subTagID: DateTime.now().millisecondsSinceEpoch, subTagName: subTagName, mainTag: mainTag));
        _subTagController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add Main Tag
                Text("Add Main Tag", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mainTagController,
                        decoration: InputDecoration(
                          hintText: "Enter main tag",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _addMainTag(dataManager),
                      child: Text("Add"),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Add Sub Tag
                Text("Add Sub Tag", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMainTag,
                  hint: Text("Select Main Tag"),
                  items: dataManager.mainTags.map((tag) {
                    return DropdownMenuItem(
                      value: tag.tagName,
                      child: Text(tag.tagName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMainTag = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subTagController,
                        decoration: InputDecoration(
                          hintText: "Enter sub tag",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _addSubTag(dataManager),
                      child: Text("Add"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
