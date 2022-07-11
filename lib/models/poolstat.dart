import 'dart:convert';

PoolStat poolStatFromJson(String str) => PoolStat.fromJson(json.decode(str));

String poolStatToJson(PoolStat data) => json.encode(data.toJson());

class PoolStat {
  PoolStat({
    required this.config,
    required this.pool,
    required this.charts,
    required this.network,
  });

  final Config config;
  final Pool pool;
  final Charts charts;
  final Network network;

  factory PoolStat.fromJson(Map<String, dynamic> json) => PoolStat(
        config: Config.fromJson(json["config"]),
        pool: Pool.fromJson(json["pool"]),
        charts: Charts.fromJson(json["charts"]),
        network: Network.fromJson(json["network"]),
      );

  Map<String, dynamic> toJson() => {
        "config": config.toJson(),
        "pool": pool.toJson(),
        "charts": charts.toJson(),
        "network": network.toJson(),
      };
}

class Charts {
  Charts({
    required this.hashrate,
    required this.workers,
    required this.difficulty,
  });

  final List<List<int>> hashrate;
  final List<List<int>> workers;
  final List<List<int>> difficulty;

  factory Charts.fromJson(Map<String, dynamic> json) => Charts(
        hashrate: List<List<int>>.from(
            json["hashrate"].map((x) => List<int>.from(x.map((x) => x)))),
        workers: List<List<int>>.from(
            json["workers"].map((x) => List<int>.from(x.map((x) => x)))),
        difficulty: List<List<int>>.from(
            json["difficulty"].map((x) => List<int>.from(x.map((x) => x)))),
      );

  Map<String, dynamic> toJson() => {
        "hashrate": List<dynamic>.from(
            hashrate.map((x) => List<dynamic>.from(x.map((x) => x)))),
        "workers": List<dynamic>.from(
            workers.map((x) => List<dynamic>.from(x.map((x) => x)))),
        "difficulty": List<dynamic>.from(
            difficulty.map((x) => List<dynamic>.from(x.map((x) => x)))),
      };
}

class Config {
  Config({
    required this.ports,
    required this.hashrateWindow,
    required this.fee,
    required this.coin,
    required this.coinUnits,
    required this.coinDifficultyTarget,
    required this.symbol,
    required this.depth,
    required this.donation,
    required this.version,
    required this.minPaymentThreshold,
    required this.denominationUnit,
    required this.blockTime,
    required this.slushMiningEnabled,
    required this.weight,
  });

  final List<Port> ports;
  final int hashrateWindow;
  final double fee;
  final String coin;
  final int coinUnits;
  final int coinDifficultyTarget;
  final String symbol;
  final int depth;
  final Donation donation;
  final String version;
  final int minPaymentThreshold;
  final int denominationUnit;
  final int blockTime;
  final bool slushMiningEnabled;
  final int weight;

  factory Config.fromJson(Map<String, dynamic> json) => Config(
        ports: List<Port>.from(json["ports"].map((x) => Port.fromJson(x))),
        hashrateWindow: json["hashrateWindow"],
        fee: json["fee"].toDouble(),
        coin: json["coin"],
        coinUnits: json["coinUnits"],
        coinDifficultyTarget: json["coinDifficultyTarget"],
        symbol: json["symbol"],
        depth: json["depth"],
        donation: Donation.fromJson(json["donation"]),
        version: json["version"],
        minPaymentThreshold: json["minPaymentThreshold"],
        denominationUnit: json["denominationUnit"],
        blockTime: json["blockTime"],
        slushMiningEnabled: json["slushMiningEnabled"],
        weight: json["weight"],
      );

  Map<String, dynamic> toJson() => {
        "ports": List<dynamic>.from(ports.map((x) => x.toJson())),
        "hashrateWindow": hashrateWindow,
        "fee": fee,
        "coin": coin,
        "coinUnits": coinUnits,
        "coinDifficultyTarget": coinDifficultyTarget,
        "symbol": symbol,
        "depth": depth,
        "donation": donation.toJson(),
        "version": version,
        "minPaymentThreshold": minPaymentThreshold,
        "denominationUnit": denominationUnit,
        "blockTime": blockTime,
        "slushMiningEnabled": slushMiningEnabled,
        "weight": weight,
      };
}

class Donation {
  Donation();

  factory Donation.fromJson(Map<String, dynamic> json) => Donation();

  Map<String, dynamic> toJson() => {};
}

class Port {
  Port({
    required this.port,
    required this.difficulty,
    required this.desc,
  });

  final int port;
  final int difficulty;
  final String desc;

  factory Port.fromJson(Map<String, dynamic> json) => Port(
        port: json["port"],
        difficulty: json["difficulty"],
        desc: json["desc"],
      );

  Map<String, dynamic> toJson() => {
        "port": port,
        "difficulty": difficulty,
        "desc": desc,
      };
}

class Network {
  Network({
    required this.difficulty,
    required this.height,
    required this.timestamp,
    required this.reward,
    required this.hash,
  });

  final int difficulty;
  final int height;
  final int timestamp;
  final int reward;
  final String hash;

  factory Network.fromJson(Map<String, dynamic> json) => Network(
        difficulty: json["difficulty"],
        height: json["height"],
        timestamp: json["timestamp"],
        reward: json["reward"],
        hash: json["hash"],
      );

  Map<String, dynamic> toJson() => {
        "difficulty": difficulty,
        "height": height,
        "timestamp": timestamp,
        "reward": reward,
        "hash": hash,
      };
}

class Pool {
  Pool({
    required this.stats,
    required this.blocks,
    required this.totalBlocks,
    required this.payments,
    required this.totalPayments,
    required this.totalMinersPaid,
    required this.miners,
    required this.hashrate,
    required this.roundHashes,
    required this.lastBlockFound,
  });

  final Stats stats;
  final List<String> blocks;
  final int totalBlocks;
  final List<String> payments;
  final int totalPayments;
  final int totalMinersPaid;
  final int miners;
  final int hashrate;
  final int roundHashes;
  final String lastBlockFound;

  factory Pool.fromJson(Map<String, dynamic> json) => Pool(
        stats: Stats.fromJson(json["stats"]),
        blocks: List<String>.from(json["blocks"].map((x) => x)),
        totalBlocks: json["totalBlocks"],
        payments: List<String>.from(json["payments"].map((x) => x)),
        totalPayments: json["totalPayments"],
        totalMinersPaid: json["totalMinersPaid"],
        miners: json["miners"],
        hashrate: json["hashrate"],
        roundHashes: json["roundHashes"],
        lastBlockFound: json["lastBlockFound"],
      );

  Map<String, dynamic> toJson() => {
        "stats": stats.toJson(),
        "blocks": List<dynamic>.from(blocks.map((x) => x)),
        "totalBlocks": totalBlocks,
        "payments": List<dynamic>.from(payments.map((x) => x)),
        "totalPayments": totalPayments,
        "totalMinersPaid": totalMinersPaid,
        "miners": miners,
        "hashrate": hashrate,
        "roundHashes": roundHashes,
        "lastBlockFound": lastBlockFound,
      };
}

class Stats {
  Stats({
    required this.lastBlockFound,
  });

  final String lastBlockFound;

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        lastBlockFound: json["lastBlockFound"],
      );

  Map<String, dynamic> toJson() => {
        "lastBlockFound": lastBlockFound,
      };
}
