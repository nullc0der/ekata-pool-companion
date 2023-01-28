import 'dart:convert';

import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/services/base.dart';
import 'package:http/http.dart' as http;

class MinerConfigService {
  static Future<String?> createMinerConfig(
      {required String userId,
      required String minerConfig,
      bool userUploaded = false}) async {
    try {
      final Map<String, dynamic> reqBody = {
        "userId": userId,
        "minerConfig": minerConfig,
        "userUploaded": userUploaded
      };
      final response = await http.post(
          Uri.parse(
              BackendApiConstants.baseUrl + BackendApiConstants.minerConfig),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(reqBody));
      if (response.statusCode == 201) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData.containsKey("minerConfigMd5")
            ? responseData["minerConfigMd5"]
            : null;
      }
      throw Exception("Failed to create miner config");
    } on Exception {
      throw Exception("Failed to create miner config");
    }
  }

  static Future<List<UsersMinerConfig>> getMinerConfig({
    required String userId,
    String? queryString,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final response = await http.get(Uri.parse(
          "${BackendApiConstants.baseUrl}${BackendApiConstants.minerConfig}"
          "?userId=$userId"
          "${queryString != null && queryString.isNotEmpty && queryString.length >= 3 ? "&queryString=$queryString" : ""}"
          "${fromDate != null ? "&fromDate=$fromDate" : ""}"
          "${toDate != null ? "&toDate=$toDate" : ""}"));
      if (response.statusCode == 200) {
        return usersMinerConfigsFromJson(response.body);
      }
      throw Exception("Failed to get miner config");
    } on Exception {
      throw Exception("Failed to get miner config");
    }
  }

  static Future<String?> updateMinerConfig(
      {required String userId,
      required String minerConfig,
      required String minerConfigMd5}) async {
    try {
      final response = await http.put(
          Uri.parse(
              "${BackendApiConstants.baseUrl}${BackendApiConstants.minerConfig}"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "userId": userId,
            "minerConfig": minerConfig,
            "minerConfigMd5": minerConfigMd5
          }));
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData.containsKey("minerConfigMd5")
            ? responseData["minerConfigMd5"]
            : null;
      }
      throw Exception("Failed to update miner config");
    } on Exception {
      throw Exception("Failed to update miner config");
    }
  }

  static Future<bool> deleteMinerConfig(
      {required String userId, required String minerConfigMd5}) async {
    try {
      final response = await http.delete(Uri.parse(
          "${BackendApiConstants.baseUrl}${BackendApiConstants.minerConfig}"
          "?userId=$userId&minerConfigMd5=$minerConfigMd5"));
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData.containsKey("deleted")
            ? responseData["deleted"]
            : false;
      }
      throw Exception("Failed to delete miner config");
    } on Exception {
      throw Exception("Failed to delete miner config");
    }
  }
}
