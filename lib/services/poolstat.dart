import 'package:ekatapoolcompanion/models/poolstat.dart';
import 'package:ekatapoolcompanion/services/base.dart';
import 'package:http/http.dart' as http;

class PoolStatService {
  Future<PoolStat> getPoolStat() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.baseUrl + ApiConstants.liveStats));
      if (response.statusCode == 200) {
        return poolStatFromJson(response.body);
      }
      throw Exception("Failed to fetch Pool Stat");
      // NOTE: Caught all exception, not a good practice, need to catch
      // individual later
    } on Exception {
      throw Exception("Failed to fetch Pool Stat");
    }
  }
}
