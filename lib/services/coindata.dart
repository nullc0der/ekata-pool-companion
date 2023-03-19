import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/services/base.dart';
import 'package:http/http.dart' as http;

class CoinDataService {
  static Future<List<CoinData>> getCoinDatas(
      {required int pageNumber,
      required int perPage,
      required String alphaSort,
      required bool newestFirst,
      required String searchQuery}) async {
    try {
      final response = await http.get(Uri.parse(
          "${BackendApiConstants.baseUrl}${BackendApiConstants.coinData}"
          "?pageNumber=$pageNumber&perPage=$perPage"
          "&alphaSort=$alphaSort&newestFirst=$newestFirst"
          "&searchQuery=$searchQuery"));
      if (response.statusCode == 200) {
        return coinDatasFromJson(response.body);
      }
      throw Exception("Failed to get coin datas");
    } on Exception {
      throw Exception("Failed to get coin datas");
    }
  }
}
