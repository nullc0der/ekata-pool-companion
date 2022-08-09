import 'package:ekatapoolcompanion/models/minersummary.dart';
import 'package:http/http.dart' as http;

class MinerSummaryService {
  Future<MinerSummary> getMinerSummary() async {
    final response =
        await http.get(Uri.parse("http://127.0.0.1:45580/2/summary"));
    if (response.statusCode == 200) {
      return minerSummaryFromJson(response.body);
    }
    throw Exception("Failed to fetch miner summary");
  }
}
