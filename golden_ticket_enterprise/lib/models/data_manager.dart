import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/faq.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/models/signalr_service.dart';

class DataManager extends ChangeNotifier {
  final SignalRService signalRService;
  List<MainTag> mainTags = [];
  List<FAQ> faqs = [];
  List<String> chatrooms = [];
  List<String> tickets = [];
  List<String> users = [];

  DataManager({required this.signalRService}) {
    _initializeSignalR();
  }

  void _initializeSignalR() {
    if (!signalRService.isConnected) {
      signalRService.onConnected = () {
        print("SignalR Connected! Attaching Events...");
        attachSignalREvents();
      };
      signalRService.startConnection(); // Start connection
    } else {
      attachSignalREvents();
    }
    signalRService.addListener(() {
      Future.microtask(() {
        notifyListeners(); // Ensures this runs after the current build completes
      });
    });
  }

  void attachSignalREvents() {
    signalRService.onTagUpdate = (updatedTags) {
      updateMainTags(updatedTags);
    };
    signalRService.onFAQUpdate = (updatedFAQs) {
      updateFAQs(updatedFAQs);
    };
  }

  void updateMainTags(List<MainTag> updatedTags) {
    mainTags = updatedTags;
    notifyListeners();
  }

  void updateFAQs(List<FAQ> updatedFAQs) {
    faqs = updatedFAQs;
    notifyListeners();
  }

  @override
  void dispose() {
    signalRService.stopConnection(); // Ensure cleanup
    super.dispose();
  }
}
