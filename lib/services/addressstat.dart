import 'dart:convert';

import 'package:ekatapoolcompanion/models/addressstat.dart';
import 'package:ekatapoolcompanion/services/base.dart';
import 'package:http/http.dart' as http;

class AddressStatService {
  Future<AddressStat> getAddressStat(String address) async {
    final response = await http.get(Uri.parse(ApiConstants.baseUrl +
        ApiConstants.addressStats +
        '?address=$address'));
    if (response.statusCode == 200) {
      return addressStatFromJson(response.body);
    }
    throw Exception("Failed to fetch Address Stat");
  }

  Future<List<String>> getAddressPayments(
      String address, int fromTimeStamp) async {
    final response = await http.get(Uri.parse(ApiConstants.baseUrl +
        ApiConstants.poolPayments +
        '?address=$address&time=$fromTimeStamp'));
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    throw Exception("Failed to fetch address payments");
  }

  Future<int> getPayoutLevel(String address) async {
    final response = await http.get(Uri.parse(ApiConstants.baseUrl +
        ApiConstants.getPayoutLevel +
        '?address=$address'));
    if (response.statusCode == 200) {
      dynamic json = jsonDecode(response.body);
      return json['level'] ?? 0;
    }
    throw Exception("Failed to fetch address payout level");
  }

  Future<bool> setPayoutLevel(String address, int level) async {
    final response = await http.get(Uri.parse(ApiConstants.baseUrl +
        ApiConstants.setPayoutLevel +
        '?address=$address&level=$level'));
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }
}
