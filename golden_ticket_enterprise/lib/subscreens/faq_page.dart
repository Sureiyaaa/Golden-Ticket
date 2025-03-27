import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/faq.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:provider/provider.dart';

class FAQPage extends StatefulWidget {
  final HiveSession? session;

  FAQPage({super.key, required this.session});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  String searchQuery = "";
  String? selectedMainTag = "All";
  String? selectedSubTag;

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {

        dataManager.signalRService.onReceiveSupport = (chatroom){
          print(chatroom.chatroomID);
          context.push('/hub/chatroom/${chatroom.chatroomID}');
        };
        dataManager.signalRService.onMaximumChatroom = (){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("You can only have a maximum of 3 chatrooms with no tickets!"),
              backgroundColor: Colors.red,
            ),
          );
        };
        List<FAQ> filteredFAQs = dataManager.faqs.where((faq) {
          bool matchesSearch = searchQuery.isEmpty || faq.title.toLowerCase().contains(searchQuery.toLowerCase());
          bool matchesMainTag = selectedMainTag == "All" || faq.mainTag!.tagName == selectedMainTag;
          bool matchesSubTag = selectedSubTag == null || faq.subTag?.subTagName == selectedSubTag;
          return matchesSearch && matchesMainTag && matchesSubTag;
        }).toList();

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: "add_faq",
            onPressed: () {
              if (widget.session!.user.role == "Employee") {
              // Request Chat Support
                 dataManager.signalRService.requestChat(widget.session!.user.userID);
              } else {
              // Navigate to Add FAQ Page
                context.push('/faq/add');
              }
            },
            child: Icon(widget.session!.user.role == "Employee" ? Icons.chat : Icons.add),
            backgroundColor: widget.session!.user.role == "Employee" ? Colors.blueAccent : kPrimary,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search FAQs...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 10),
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMainTag,
                        hint: Text("Main Tag"),
                        items: ["All", ...dataManager.mainTags.map((tag) => tag.tagName)].map((tag) {
                          return DropdownMenuItem(
                            value: tag,
                            child: Text(tag),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMainTag = value;
                            selectedSubTag = null;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSubTag,
                        hint: selectedMainTag == 'All' ? Text('Select a main tag first...'): Text("Select a Sub tag..."),
                        items: dataManager.mainTags
                            .where((tag) => tag.tagName == selectedMainTag)
                            .expand((tag) => tag.subTags.map((subTag) => subTag.subTagName))
                            .map((subTag) => DropdownMenuItem(
                          value: subTag,
                          child: Text(subTag),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSubTag = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // FAQ List
                Expanded(
                  child: filteredFAQs.isEmpty
                      ? Center(child: Text("No FAQs found"))
                      : ListView.builder(
                    itemCount: filteredFAQs.length,
                    itemBuilder: (context, index) {
                      var faq = filteredFAQs[index];
                      return ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                faq.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                if(faq.mainTag != null) Chip(backgroundColor: Colors.redAccent,label: Text(faq.mainTag!.tagName, style: TextStyle(fontWeight: FontWeight.bold, color: kSurface),)),
                                SizedBox(width: 5),
                                if(faq.subTag != null) Chip(backgroundColor: Colors.blueAccent,label: Text(faq.subTag!.subTagName, style: TextStyle(fontWeight: FontWeight.bold, color: kSurface))),
                              ],
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  faq.description,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Solution:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(faq.solution),
                                SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    child: Text("View Ticket Related"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
