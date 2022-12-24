import 'package:ekatapoolcompanion/services/base.dart';
import 'package:http/http.dart' as http;

class AppVersionService {
  static Future<bool> addAppVersion(
      {required String userId, required String appVersion}) async {
    try {
      final response = await http.post(
          Uri.parse(
              BackendApiConstants.baseUrl + BackendApiConstants.appVersion),
          body: {"userId": userId, "appVersion": appVersion});
      if (response.statusCode == 201) {
        return true;
      }
      throw Exception("Failed to add appversion");
    } on Exception {
      throw Exception("Failed to add appversion");
    }
  }
}
