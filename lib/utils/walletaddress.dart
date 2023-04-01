import 'dart:convert';

import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String>> getPoolCredentials(String poolAddress) async {
  final poolCredentials = {"walletAddress": "", "password": "", "rigId": ""};
  final prefs = await SharedPreferences.getInstance();
  String walletAddresses =
      prefs.getString(Constants.walletAddressesKeySharedPrefs) ?? "";
  if (walletAddresses.isNotEmpty) {
    var addressesJson = jsonDecode(walletAddresses);
    var addresses =
        addressesJson.where((address) => address["poolAddress"] == poolAddress);
    if (addresses.isNotEmpty) {
      final address = addresses.first;
      final rigId = address["rigId"] != null
          ? address["rigId"].isNotEmpty
              ? address["rigId"]
              : getRandomString(6)
          : getRandomString(6);
      poolCredentials["walletAddress"] = address["walletAddress"] ?? "";
      poolCredentials["password"] = address["password"] ?? "";
      poolCredentials["rigId"] = rigId;
    }
  }
  return poolCredentials;
}
