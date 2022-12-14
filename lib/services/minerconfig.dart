import 'package:ekatapoolcompanion/services/base.dart';
import 'package:http/http.dart' as http;

class MinerConfigService {
  static Future<bool> createMinerConfig(
      {required String userId, required String minerConfig}) async {
    try {
      final response = await http.post(
          Uri.parse(
              BackendApiConstants.baseUrl + BackendApiConstants.minerConfig),
          body: {"userId": userId, "minerConfig": minerConfig});
      if (response.statusCode == 201) {
        return true;
      }
      throw Exception("Failed to create miner config");
    } on Exception {
      throw Exception("Failed to create miner config");
    }
  }
}
