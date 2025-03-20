import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:golden_ticket_enterprise/models/http_request.dart' as http;

class DataManager extends ChangeNotifier {
  List<MainTag> mainTags = [];

  DataManager() {
    initializeData();
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
}
