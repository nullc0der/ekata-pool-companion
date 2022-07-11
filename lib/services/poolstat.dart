import 'package:ekatapoolcompanion/models/poolstat.dart';
import 'package:ekatapoolcompanion/services/base.dart';
import 'package:http/http.dart' as http;

class PoolStatService {
  Future<PoolStat> getPoolStat() async {
    final response = await http
        .get(Uri.parse(ApiConstants.baseUrl + ApiConstants.liveStats));
    if (response.statusCode == 200) {
      return poolStatFromJson(response.body);
    }
    throw Exception("Failed to fetch Pool Stat");
  }
}
