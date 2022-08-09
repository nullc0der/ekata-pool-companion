// To parse this JSON data, do
//
//     final minerStat = minerStatFromJson(jsonString);

import 'dart:convert';

MinerSummary minerSummaryFromJson(String str) =>
    MinerSummary.fromJson(json.decode(str));

String minerSummaryToJson(MinerSummary data) => json.encode(data.toJson());

class MinerSummary {
  MinerSummary({
    required this.id,
    required this.workerId,
    required this.uptime,
    required this.restricted,
    required this.resources,
    required this.features,
    required this.results,
    required this.algo,
    required this.connection,
    required this.version,
    required this.kind,
    required this.ua,
    required this.cpu,
    required this.donateLevel,
    required this.paused,
    required this.algorithms,
    required this.hashrate,
    required this.hugepages,
  });

  final String id;
  final String workerId;
  final int uptime;
  final bool restricted;
  final Resources resources;
  final List<String> features;
  final Results results;
  final String algo;
  final Connection connection;
  final String version;
  final String kind;
  final String ua;
  final Cpu cpu;
  final int donateLevel;
  final bool paused;
  final List<String> algorithms;
  final Hashrate hashrate;
  final List<int> hugepages;

  factory MinerSummary.fromJson(Map<String, dynamic> json) => MinerSummary(
        id: json["id"],
        workerId: json["worker_id"],
        uptime: json["uptime"],
        restricted: json["restricted"],
        resources: Resources.fromJson(json["resources"]),
        features: List<String>.from(json["features"].map((x) => x)),
        results: Results.fromJson(json["results"]),
        algo: json["algo"],
        connection: Connection.fromJson(json["connection"]),
        version: json["version"],
        kind: json["kind"],
        ua: json["ua"],
        cpu: Cpu.fromJson(json["cpu"]),
        donateLevel: json["donate_level"],
        paused: json["paused"],
        algorithms: List<String>.from(json["algorithms"].map((x) => x)),
        hashrate: Hashrate.fromJson(json["hashrate"]),
        hugepages: List<int>.from(json["hugepages"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "worker_id": workerId,
        "uptime": uptime,
        "restricted": restricted,
        "resources": resources.toJson(),
        "features": List<dynamic>.from(features.map((x) => x)),
        "results": results.toJson(),
        "algo": algo,
        "connection": connection.toJson(),
        "version": version,
        "kind": kind,
        "ua": ua,
        "cpu": cpu.toJson(),
        "donate_level": donateLevel,
        "paused": paused,
        "algorithms": List<dynamic>.from(algorithms.map((x) => x)),
        "hashrate": hashrate.toJson(),
        "hugepages": List<dynamic>.from(hugepages.map((x) => x)),
      };
}

class Connection {
  Connection({
    required this.pool,
    required this.ip,
    required this.uptime,
    required this.uptimeMs,
    required this.ping,
    required this.failures,
    required this.tls,
    required this.tlsFingerprint,
    required this.algo,
    required this.diff,
    required this.accepted,
    required this.rejected,
    required this.avgTime,
    required this.avgTimeMs,
    required this.hashesTotal,
  });

  final String pool;
  final String ip;
  final int uptime;
  final int uptimeMs;
  final int ping;
  final int failures;
  final dynamic tls;
  final dynamic tlsFingerprint;
  final String algo;
  final int diff;
  final int accepted;
  final int rejected;
  final int avgTime;
  final int avgTimeMs;
  final int hashesTotal;

  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
        pool: json["pool"],
        ip: json["ip"],
        uptime: json["uptime"],
        uptimeMs: json["uptime_ms"],
        ping: json["ping"],
        failures: json["failures"],
        tls: json["tls"],
        tlsFingerprint: json["tls-fingerprint"],
        algo: json["algo"],
        diff: json["diff"],
        accepted: json["accepted"],
        rejected: json["rejected"],
        avgTime: json["avg_time"],
        avgTimeMs: json["avg_time_ms"],
        hashesTotal: json["hashes_total"],
      );

  Map<String, dynamic> toJson() => {
        "pool": pool,
        "ip": ip,
        "uptime": uptime,
        "uptime_ms": uptimeMs,
        "ping": ping,
        "failures": failures,
        "tls": tls,
        "tls-fingerprint": tlsFingerprint,
        "algo": algo,
        "diff": diff,
        "accepted": accepted,
        "rejected": rejected,
        "avg_time": avgTime,
        "avg_time_ms": avgTimeMs,
        "hashes_total": hashesTotal,
      };
}

class Cpu {
  Cpu({
    required this.brand,
  });

  final String brand;

  factory Cpu.fromJson(Map<String, dynamic> json) => Cpu(
        brand: json["brand"],
      );

  Map<String, dynamic> toJson() => {
        "brand": brand,
      };
}

class Hashrate {
  Hashrate({
    required this.total,
    required this.highest,
  });

  final List<double?> total;
  final dynamic highest;

  factory Hashrate.fromJson(Map<String, dynamic> json) => Hashrate(
        total: List<double?>.from(json["total"].map((x) => x)),
        highest: json["highest"],
      );

  Map<String, dynamic> toJson() => {
        "total": List<dynamic>.from(total.map((x) => x)),
        "highest": highest,
      };
}

class Resources {
  Resources({
    required this.memory,
    required this.loadAverage,
    required this.hardwareConcurrency,
  });

  final Memory memory;
  final List<double> loadAverage;
  final int hardwareConcurrency;

  factory Resources.fromJson(Map<String, dynamic> json) => Resources(
        memory: Memory.fromJson(json["memory"]),
        loadAverage:
            List<double>.from(json["load_average"].map((x) => x.toDouble())),
        hardwareConcurrency: json["hardware_concurrency"],
      );

  Map<String, dynamic> toJson() => {
        "memory": memory.toJson(),
        "load_average": List<dynamic>.from(loadAverage.map((x) => x)),
        "hardware_concurrency": hardwareConcurrency,
      };
}

class Memory {
  Memory({
    required this.free,
    required this.total,
    required this.residentSetMemory,
  });

  final int free;
  final int total;
  final int residentSetMemory;

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
        free: json["free"],
        total: json["total"],
        residentSetMemory: json["resident_set_memory"],
      );

  Map<String, dynamic> toJson() => {
        "free": free,
        "total": total,
        "resident_set_memory": residentSetMemory,
      };
}

class Results {
  Results({
    required this.diffCurrent,
    required this.sharesGood,
    required this.sharesTotal,
    required this.avgTime,
    required this.avgTimeMs,
    required this.hashesTotal,
    required this.best,
  });

  final int diffCurrent;
  final int sharesGood;
  final int sharesTotal;
  final int avgTime;
  final int avgTimeMs;
  final int hashesTotal;
  final List<int> best;

  factory Results.fromJson(Map<String, dynamic> json) => Results(
        diffCurrent: json["diff_current"],
        sharesGood: json["shares_good"],
        sharesTotal: json["shares_total"],
        avgTime: json["avg_time"],
        avgTimeMs: json["avg_time_ms"],
        hashesTotal: json["hashes_total"],
        best: List<int>.from(json["best"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "diff_current": diffCurrent,
        "shares_good": sharesGood,
        "shares_total": sharesTotal,
        "avg_time": avgTime,
        "avg_time_ms": avgTimeMs,
        "hashes_total": hashesTotal,
        "best": List<dynamic>.from(best.map((x) => x)),
      };
}
