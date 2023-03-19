import 'dart:convert';

List<CoinData> coinDatasFromJson(String string) => List<CoinData>.from(
    jsonDecode(string)["results"].map((x) => CoinData.fromJson(x)));

String coinDatasToJson(List<CoinData> coinDatas) =>
    jsonEncode(coinDatas.map((x) => x.toJson()));

class CoinData {
  CoinData(
      {required this.coinName,
      required this.coinLogoUrl,
      required this.pools,
      required this.coinAlgo,
      required this.cpuMineable,
      required this.supportedMiningEngines});

  final String coinName;
  final String coinLogoUrl;
  final List<Pool> pools;
  final String coinAlgo;
  final bool cpuMineable;
  final List<String> supportedMiningEngines;

  factory CoinData.fromJson(Map<String, dynamic> json) => CoinData(
      coinName: json["coinName"],
      coinLogoUrl: json["coinLogoUrl"],
      pools: List<Pool>.from(json["pools"].map((e) => Pool.fromJson(e))),
      coinAlgo: json["coinAlgo"],
      cpuMineable: json["cpuMineable"],
      supportedMiningEngines:
          List<String>.from(json["supportedMiningEngines"].map((e) => e)));

  Map<String, dynamic> toJson() => {
        "coinName": coinName,
        "coinLogoUrl": coinLogoUrl,
        "pools": pools,
        "coinAlgo": coinAlgo,
        "cpuMineable": cpuMineable,
        "supportedMiningEngines": supportedMiningEngines
      };
}

class Pool {
  Pool(
      {required this.poolName,
      required this.region,
      required this.urls,
      required this.ports});

  final String poolName;
  final String region;
  final List<String> urls;
  final List<int> ports;

  factory Pool.fromJson(Map<String, dynamic> json) => Pool(
      poolName: json["poolName"],
      region: json["region"],
      urls: List<String>.from(json["urls"].map((e) => e)),
      ports: List<int>.from(json["ports"].map((e) => int.tryParse(e) ?? 0)));

  Map<String, dynamic> toJson() =>
      {"poolName": poolName, "region": region, "urls": urls, "ports": ports};
}
