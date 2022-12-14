import 'dart:convert';

import 'package:ekatapoolcompanion/services/base.dart';
import 'package:http/http.dart' as http;

class UserIdService {
  static Future<String> createUserId() async {
    try {
      final response = await http.post(
          Uri.parse(BackendApiConstants.baseUrl + BackendApiConstants.userId));
      if (response.statusCode == 201) {
        return jsonDecode(response.body)["data"]["userId"];
      }
      throw Exception("Failed to create user id");
    } on Exception {
      throw Exception("Failed to create user id");
    }
  }
}
