import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/signalr/signalr_service.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
import 'package:golden_ticket_enterprise/widgets/ticket_detail_widget.dart';
import 'package:golden_ticket_enterprise/widgets/ticket_tile_widget.dart';
import 'package:provider/provider.dart';
class RelatedTicketWidget extends StatefulWidget {
  final HiveSession session;
  final String? mainTag;
  final String? subTag;
  const RelatedTicketWidget({Key? key, required this.session, required this.mainTag, required this.subTag}) : super(key: key);
  @override
  _RelatedTicketWidgetState createState() => _RelatedTicketWidgetState();
}

class _RelatedTicketWidgetState extends State<RelatedTicketWidget> {

  // Function to show the popup
  void handleChat(DataManager dataManager, Ticket ticket) {
    try {
      openChatroom(context, widget.session, dataManager, dataManager.findChatroomByTicketID(ticket.ticketID)!.chatroomID);
    } catch (err) {
      TopNotification.show(
          context: context,
          message: "Error chatroom could not be found!",
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
          textColor: Colors.white,
          onTap: () {
            TopNotification.dismiss();
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size from MediaQuery
    Size screenSize = MediaQuery.of(context).size;

    // Define the responsive width and height as a percentage of the screen size
    double dialogWidth = screenSize.width * 0.8; // 80% of screen width
    double dialogHeight = screenSize.height * 0.6; // 60% of screen height

    return
      Consumer<DataManager>(
        builder: (context, dataManager, child) {
      List<Ticket> relatedTicket = dataManager.getTicketRelated(
          widget.mainTag ?? '', widget.subTag ?? '');

      return AlertDialog(
        title: const Text('List of Related Tickets'),
        content: Container(
            width: dialogWidth,
            height: dialogHeight,
            child:  relatedTicket.isEmpty ? Text('No related tickets found!') : ListView.builder(
              itemCount: relatedTicket.length,
              itemBuilder: (context, index) {
                return TicketTile(
                  session: widget.session,
                  ticket: relatedTicket[index],
                  onViewPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          TicketDetailsPopup(
                            ticket: relatedTicket[index],
                            onChatPressed: () {
                              // Add logic to handle chat button press
                            },
                          ),
                    );
                  },
                  onChatPressed: () {
                    handleChat(dataManager, relatedTicket[index]);
                  },
                  onEditPressed: () {

                  },
                );
              },
            )
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the popup when 'Close' is pressed
            },
            child: const Text('Close'),
          ),
        ],
      );
    }
    );
  }
}