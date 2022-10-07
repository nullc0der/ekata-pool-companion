import 'dart:convert';

import 'package:ekatapoolcompanion/services/base.dart';
import 'package:http/http.dart' as http;

class PoolBlockService {
  Future<List<String>> getPoolBlocks(int lastHeight) async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.baseUrl +
          ApiConstants.poolBlocks +
          '?height=$lastHeight'));
      if (response.statusCode == 200) {
        return List<String>.from(jsonDecode(response.body));
      }
      throw Exception("Failed to fetch Pool Block");
    } on Exception {
      throw Exception("Failed to fetch Pool Block");
    }
  }
}
