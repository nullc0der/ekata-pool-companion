import 'dart:convert';

AddressStat addressStatFromJson(String str) =>
    AddressStat.fromJson(json.decode(str));

String addressStatToJson(AddressStat data) => json.encode(data.toJson());

class AddressStat {
  AddressStat({
    required this.stats,
    required this.payments,
    required this.charts,
    required this.workers,
  });

  final Stats stats;
  final List<String> payments;
  final Charts charts;
  final List<dynamic> workers;

  factory AddressStat.fromJson(Map<String, dynamic> json) => AddressStat(
        stats: Stats.fromJson(json["stats"]),
        payments: List<String>.from(json["payments"].map((x) => x)),
        charts: Charts.fromJson(json["charts"]),
        workers: List<dynamic>.from(json["workers"].map((x) => x)),
      );

  // TODO: If the wallet address is new and no stats in pool this throws error
  // need to handle it, we need to check if no data based on it we need to show
  // error message in account_stats widget, it affects both new address and change
  // address mechanism
  Map<String, dynamic> toJson() => {
        "stats": stats.toJson(),
        "payments": List<dynamic>.from(payments.map((x) => x)),
        "charts": charts.toJson(),
        "workers": List<dynamic>.from(workers.map((x) => x)),
      };
}

class Charts {
  Charts({
    required this.payments,
    required this.hashrate,
  });

  final List<List<dynamic>> payments;
  final List<dynamic> hashrate;

  factory Charts.fromJson(Map<String, dynamic> json) => Charts(
        payments: List<List<dynamic>>.from(
            json["payments"].map((x) => List<dynamic>.from(x.map((x) => x)))),
        hashrate: List<dynamic>.from(json["hashrate"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "payments": List<dynamic>.from(
            payments.map((x) => List<dynamic>.from(x.map((x) => x)))),
        "hashrate": List<dynamic>.from(hashrate.map((x) => x)),
      };
}

class Stats {
  Stats({
    required this.hashes,
    required this.lastShare,
    required this.balance,
    required this.paid,
    required this.minPayoutLevel,
    required this.hashrate,
  });

  final String hashes;
  final String lastShare;
  final String balance;
  final String paid;
  final String minPayoutLevel;
  final String hashrate;

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        hashes: json["hashes"],
        lastShare: json["lastShare"],
        balance: json["balance"],
        paid: json["paid"],
        minPayoutLevel: json["minPayoutLevel"] ?? '2',
        hashrate: json["hashrate"] ?? "0",
      );

  Map<String, dynamic> toJson() => {
        "hashes": hashes,
        "lastShare": lastShare,
        "balance": balance,
        "paid": paid,
        "minPayoutLevel": minPayoutLevel,
        "hashrate": hashrate,
      };
}
