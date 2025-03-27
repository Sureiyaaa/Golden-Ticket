import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';

class TicketsPage extends StatefulWidget {
  final HiveSession? session;

  TicketsPage({super.key, required this.session});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  List<String> _tickets = List.generate(20, (index) => "Ticket #${index + 1}");
  List<String> _filteredTickets = [];

  String? selectedStatus = 'All';
  String? selectedMainTag = 'All';
  String? selectedSubTag;

  final List<String> statuses = ['All', 'Open', 'Closed', 'In Progress'];

  @override
  void initState() {
    super.initState();
    if (widget.session == null) {
      context.go("/login");
    }
    _filteredTickets = List.from(_tickets);
  }

  void _filterTickets(String query) {
    setState(() {
      _filteredTickets = _tickets
          .where((ticket) => ticket.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        // Ensure UI updates when tags change
        Map<String, List<String>> tags = {
          'All': [], // Add "All" as the default option
          for (var tag in dataManager.mainTags)
            tag.tagName: tag.subTags.map((e) => e.subTagName).toList(),
        };

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // If still loading, show progress indicator
              if (dataManager.mainTags.isEmpty)
                Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    // Status Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        hint: Text("Select Status"),
                        items: statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),

                    // Main Tag Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMainTag,
                        hint: Text("Select Main Tag"),
                        items: tags.keys.map((tag) {
                          return DropdownMenuItem(
                            value: tag,
                            child: Text(tag),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMainTag = value;
                            selectedSubTag = null; // Reset subtag
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),

                    // Sub Tag Dropdown (Disabled if "All" is selected)
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSubTag,
                        hint: Text("Select Sub Tag"),
                        items: (tags[selectedMainTag] ?? []).map((subtag) {
                          return DropdownMenuItem(
                            value: subtag,
                            child: Text(subtag),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSubTag = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),),
                    ),
                  ],
                ),
              SizedBox(height: 10),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: _filterTickets,
                decoration: InputDecoration(
                  hintText: "Search tickets...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 10),

              // Ticket List with Scrollbar
              Expanded(
                child: Scrollbar(
                  controller: scrollController, // Attach ScrollController to Scrollbar
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: scrollController, // Attach ScrollController to ListView
                    itemCount: _filteredTickets.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.confirmation_number),
                          title: Text(_filteredTickets[index]),
                          subtitle: Text("Issue: Sample issue description"),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            // Navigate to Ticket Details
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
