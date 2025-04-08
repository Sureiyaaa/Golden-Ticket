import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
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
      dataManager.signalRService.addMainTag(tagName);
      _mainTagController.clear();
    }
  }

  void _addSubTag(DataManager dataManager) {
    String subTagName = _subTagController.text.trim();
    if (subTagName.isNotEmpty && selectedMainTag != null) {
      MainTag? mainTag = dataManager.mainTags.firstWhere(
            (tag) => tag.tagName == selectedMainTag,
        orElse: () => MainTag(tagID: -1, tagName: '', subTags: []),
      );

      if (mainTag.tagID != -1) {
        dataManager.signalRService.addSubTag(subTagName, mainTag.tagName);
        _subTagController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        dataManager.signalRService.onExistingTag = () {
          TopNotification.show(
              context: context,
              message: "The tag that you're trying to add is already existing!",
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
              textColor: Colors.white,
              onTap: () {
                TopNotification.dismiss();
              }
          );
        };

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **Add Main Tag**
                  Text("Add Main Tag", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mainTagController,
                          decoration: InputDecoration(
                            hintText: "Enter main tag",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _addMainTag(dataManager),
                        icon: Icon(Icons.add),
                        label: Text("Add"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // **Add Sub Tag**
                  Text("Add Sub Tag", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subTagController,
                          decoration: InputDecoration(
                            hintText: "Enter sub tag",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _addSubTag(dataManager),
                        icon: Icon(Icons.add),
                        label: Text("Add"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),

                  // **Available Tags**
                  Text("Available Tags", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  dataManager.mainTags.isEmpty
                      ? Center(child: Text("No tags available", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: dataManager.mainTags.length,
                    itemBuilder: (context, index) {
                      MainTag mainTag = dataManager.mainTags[index];
                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Icon(Icons.label, color: Colors.blueGrey),
                              SizedBox(width: 8),
                              Text(mainTag.tagName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          children: mainTag.subTags.isEmpty
                              ? [
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Text("No sub-tags", style: TextStyle(color: Colors.grey)),
                            )
                          ]
                              : mainTag.subTags.map((subTag) {
                            return ListTile(
                              leading: Icon(Icons.subdirectory_arrow_right, color: Colors.grey),
                              title: Text(subTag.subTagName, style: TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
