import 'dart:convert';

import 'package:ekatapoolcompanion/services/base.dart';
import 'package:http/http.dart' as http;

class SystemInfoService {
  static Future<bool> uploadSystemInfo(
      {required String userId,
      required Map<String, dynamic> systemInfo}) async {
    try {
      final response = await http.post(
          Uri.parse(
              BackendApiConstants.baseUrl + BackendApiConstants.systemInfo),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({...systemInfo, "userId": userId}));
      if (response.statusCode == 201) {
        return true;
      }
      throw Exception("Failed to upload system info");
    } on Exception {
      throw Exception("Failed to upload system info");
    }
  }
}
