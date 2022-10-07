import 'dart:convert';

import 'package:ekatapoolcompanion/services/base.dart';
import 'package:http/http.dart' as http;

class PoolPaymentService {
  Future<List<String>> getPoolPayments(int lastPaymentTimeStamp) async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.baseUrl +
          ApiConstants.poolPayments +
          '?time=$lastPaymentTimeStamp'));
      if (response.statusCode == 200) {
        return List<String>.from(jsonDecode(response.body));
      }
      throw Exception("Failed to fetch pool payments");
    } on Exception {
      throw Exception("Failed to fetch pool payments");
    }
  }
}
