import 'dart:convert';

List<CoinData> coinDatasFromJson(String string) =>
    List<CoinData>.from(jsonDecode(string).map((x) => CoinData.fromJson(x)));

String coinDatasToJson(List<CoinData> coinDatas) =>
    jsonEncode(coinDatas.map((x) => x.toJson()));

class CoinData {
  CoinData(
      {required this.coinName,
      required this.coinLogoPath,
      required this.poolAddress,
      required this.poolPortCPU,
      required this.poolPortGPU,
      required this.coinAlgo,
      required this.cpuMineable});

  final String coinName;
  final String coinLogoPath;
  final String poolAddress;
  final int poolPortCPU;
  final int poolPortGPU;
  final String coinAlgo;
  final bool cpuMineable;

  factory CoinData.fromJson(Map<String, dynamic> json) => CoinData(
      coinName: json["coinName"],
      coinLogoPath: json["coinLogoPath"],
      poolAddress: json["poolAddress"],
      poolPortCPU: json["poolPortCPU"],
      poolPortGPU: json["poolPortGPU"],
      coinAlgo: json["coinAlgo"],
      cpuMineable: json["cpuMineable"]);

  Map<String, dynamic> toJson() => {
        "coinName": coinName,
        "coinLogoPath": coinLogoPath,
        "poolAddress": poolAddress,
        "poolPortCPU": poolPortCPU,
        "poolPortGPU": poolPortGPU,
        "coinAlgo": coinAlgo,
        "cpuMineable": cpuMineable
      };
}
