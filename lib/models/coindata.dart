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
      required this.poolPort,
      required this.coinAlgo});

  final String coinName;
  final String coinLogoPath;
  final String poolAddress;
  final int poolPort;
  final String coinAlgo;

  factory CoinData.fromJson(Map<String, dynamic> json) => CoinData(
      coinName: json["coinName"],
      coinLogoPath: json["coinLogoPath"],
      poolAddress: json["poolAddress"],
      poolPort: json["poolPort"],
      coinAlgo: json["coinAlgo"]);

  Map<String, dynamic> toJson() => {
        "coinName": coinName,
        "coinLogoPath": coinLogoPath,
        "poolAddress": poolAddress,
        "poolPort": poolPort,
        "coinAlgo": coinAlgo
      };
}
