import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/faq.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/models/gt_hub.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:golden_ticket_enterprise/models/http_request.dart' as http;

class DataManager extends ChangeNotifier {
  final SignalRService signalRService;
  List<MainTag> mainTags = [];
  List<FAQ> faqs = [];
  DataManager({required this.signalRService}) {
    initializeData();
    signalRService.onTagUpdate = (List<MainTag> updatedTags) {
      updateMainTags(updatedTags);
    };

    signalRService.onFAQUpdate = (List<FAQ> updatedFAQs){
      updateFAQs(updatedFAQs);
    };
  }

  Future<void> initializeData() async {
    var url = Uri.http(kBaseURL, kGetTags);

    var response = await http.requestJson(
      url,
      method: http.RequestMethod.get,
    );

    if (response['status'] == 200) {
      mainTags = (response['body']['tags'] as List)
          .map((tag) => MainTag.fromJson(tag))
          .toList();

      notifyListeners(); // Notify UI that data has changed
    }
  }
  void updateMainTags(List<MainTag> updatedTags) {
    mainTags = updatedTags;
    notifyListeners(); // Broadcast update to all listeners
  }
  void updateFAQs(List<FAQ> updatedFAQs) {
    faqs = updatedFAQs;
    notifyListeners(); // Broadcast update to all listeners
  }
}
