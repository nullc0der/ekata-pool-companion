// TODO: Need to change this to adapt multi pool architecture, maybe use
// getter, setter and constructor

import 'package:flutter/foundation.dart';

class ApiConstants {
  static String baseUrl = 'https://pool.baza.foundation/api/v2';
  static String liveStats = '/live_stats';
  static String poolBlocks = '/get_blocks';
  static String poolPayments = '/get_payments';
  static String addressStats = '/stats_address';
  static String getPayoutLevel = '/get_miner_payout_level';
  static String setPayoutLevel = '/set_miner_payout_level';
}

class BackendApiConstants {
  static String baseUrl = kDebugMode
      ? "http://localhost:3000/api/v1"
      : "https://poolcompanion.ekata.io/api/v1";
  static String userId = "/userid";
  static String minerConfig = "/minerconfig";
  static String systemInfo = "/systeminfo";
}
