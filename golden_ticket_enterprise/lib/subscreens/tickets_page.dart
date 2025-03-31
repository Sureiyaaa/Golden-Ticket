import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/widgets/ticket_tile_widget.dart';
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
  List<Ticket> _filteredTickets = [];

  String? selectedStatus = 'All';
  String? selectedMainTag = 'All';
  String? selectedSubTag;

  @override
  void initState() {
    super.initState();
    if (widget.session == null) {
      context.go("/login");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dataManager = Provider.of<DataManager>(context, listen: true);

    // Ensure tickets are loaded before applying filters
    if (dataManager.tickets.isNotEmpty) {
      _applyFilters(dataManager);
    }
  }

  void _applyFilters(DataManager dataManager) {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredTickets = dataManager.tickets.where((ticket) {
        bool matchesSearch = ticket.ticketTitle.toLowerCase().contains(query);
        bool matchesStatus =
            selectedStatus == 'All' || ticket.status == selectedStatus;
        bool matchesMainTag = selectedMainTag == 'All' ||
            (ticket.mainTag?.tagName == selectedMainTag);
        bool matchesSubTag = selectedSubTag == 'All' ||
            selectedSubTag == null ||
            (ticket.subTag?.subTagName == selectedSubTag);

        return matchesSearch &&
            matchesStatus &&
            matchesMainTag &&
            matchesSubTag;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        Map<String, List<String>> tags = {
          'All': [],
          for (var tag in dataManager.mainTags)
            tag.tagName: tag.subTags.map((e) => e.subTagName).toList(),
        };

        List<String> statuses = ['All', ...dataManager.status];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dataManager.mainTags.isEmpty)
                    Center(child: CircularProgressIndicator())
                  else
                    ExpansionTile(
                      initiallyExpanded:
                          isMobile, // ✅ Expanded by default on mobile, collapsed on desktop
                      title: Text("Filters",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        _buildFilters(tags, statuses, isRow: !isMobile)
                      ],
                    ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(dataManager),
                    decoration: InputDecoration(
                      hintText: "Search tickets...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: _filteredTickets.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? "No tickets available"
                                  : "No tickets found",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            ),
                          )
                        : Scrollbar(
                            controller: scrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: _filteredTickets.length,
                              itemBuilder: (context, index) {
                                final ticket = _filteredTickets[index];
                                return TicketTile(
                                  title: ticket.ticketTitle,
                                  mainTag: ticket.mainTag?.tagName ??
                                      'No main tag provided',
                                  subTag: ticket.subTag?.subTagName ??
                                      'No sub tag provided',
                                  onChatPressed: () {
                                    context.push(
                                        '/hub/chatroom/${ticket.chatroomID}');
                                    dataManager.signalRService.openChatroom(
                                        widget.session!.user.userID,
                                        ticket.chatroomID);
                                  },
                                  onEditPressed: () {},
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilters(Map<String, List<String>> tags, List<String> statuses,
      {bool isRow = false}) {
    List<Widget> filterWidgets = [
      _buildDropdown("Select Status", selectedStatus, statuses, (value) {
        setState(() {
          selectedStatus = value;
        });
        _applyFilters(Provider.of<DataManager>(context, listen: false));
      }),
      _buildDropdown("Select Main Tag", selectedMainTag, tags.keys.toList(),
          (value) {
        setState(() {
          selectedMainTag = value;
          selectedSubTag = null;
        });
        _applyFilters(Provider.of<DataManager>(context, listen: false));
      }),
      _buildDropdown(
          "Select Sub Tag", selectedSubTag, ['All', ...?tags[selectedMainTag]],
          (value) {
        setState(() {
          selectedSubTag = value;
        });
        _applyFilters(Provider.of<DataManager>(context, listen: false));
      }),
    ];

    return isRow
        ? Row(
            children: filterWidgets
                .expand(
                    (widget) => [Expanded(child: widget), SizedBox(width: 10)])
                .toList()
              ..removeLast(),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: filterWidgets
                .expand((widget) => [widget, SizedBox(height: 10)])
                .toList()
              ..removeLast(),
          );
  }

  Widget _buildDropdown(String hint, String? value, List<String>? items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      items: (items ?? [])
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}
