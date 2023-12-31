// NOTE: CPU Thread: Xmrig need thread option set per algo basis on config file
// so once user selects the coin we need to set thread option based on its algo,
// for now if user provides this in config.json it will be used, otherwise if
// user defines through thread count input it will pass the value as command line
// arg instead, cmd line arg don't need it per algo basis

// TODO: Based on GPU availability backend should be selected

import 'dart:convert';

import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';

MinerConfig minerConfigFromJson(String str, MinerBinary minerBinary) =>
    MinerConfig.fromJson(json.decode(str), minerBinary);

String minerConfigToJson(MinerConfig data, {bool prettyPrint = false}) {
  if (prettyPrint) {
    var encoder = JsonEncoder.withIndent(" " * 2);
    return encoder.convert(data.toJson());
  }
  return json.encode(data.toJson());
}

List<UsersMinerConfig> usersMinerConfigsFromJson(String str) {
  return List.from(json.decode(str))
      .map((e) => UsersMinerConfig.fromJson(e))
      .toList();
}

String usersMinerConfigsToJson(List<UsersMinerConfig> usersMinerConfigs) =>
    json.encode(usersMinerConfigs);

class MinerConfig {
  MinerConfig({
    this.cpu,
    this.opencl,
    this.cuda,
    required this.pools,
  });

  Cpu? cpu;
  Gpu? opencl;
  Gpu? cuda;
  List<Pool> pools;

  factory MinerConfig.fromJson(
      Map<String, dynamic> json, MinerBinary minerBinary) {
    if (!json.containsKey("pools") || json["pools"].isEmpty) {
      throw const FormatException("Make sure to add atleast one pool block");
    }
    if (!json.containsKey("cpu") &&
        !json.containsKey("cuda") &&
        !json.containsKey("opencl")) {
      throw const FormatException(
          "Make sure to add atleast one mining backend, such as CPU, CUDA or OpenCl");
    }
    MinerConfig config = MinerConfig(
      pools: List<Pool>.from(
          json["pools"].map((x) => Pool.fromJson(x, minerBinary))),
    );
    if (json.containsKey("cpu")) {
      config.cpu = Cpu.fromJson(json["cpu"]);
    }
    if (json.containsKey("cuda")) {
      config.cuda = Gpu.fromJson(json["cuda"]);
    }
    if (json.containsKey("opencl")) {
      config.opencl = Gpu.fromJson(json["opencl"]);
    }
    return config;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      "pools": List<dynamic>.from(pools.map((x) => x.toJson())),
    };
    if (cpu != null) {
      json["cpu"] = cpu!.toJson();
    }
    if (opencl != null) {
      json["opencl"] = opencl!.toJson();
    }
    if (cuda != null) {
      json["cuda"] = cuda!.toJson();
    }
    return json;
  }
}

class Cpu {
  Cpu({
    required this.enabled,
  });

  bool enabled;

  factory Cpu.fromJson(Map<String, dynamic> json) => Cpu(
        enabled: json["enabled"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
      };
}

class Gpu {
  Gpu({
    required this.enabled,
    this.loader,
  });

  bool enabled;
  String? loader;

  factory Gpu.fromJson(Map<String, dynamic> json) => Gpu(
        enabled: json["enabled"],
        loader: json["loader"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "loader": loader,
      };
}

class Pool {
  Pool({
    required this.url,
    required this.user,
    this.algo,
    this.pass,
    this.rigId,
  });

  String? algo;
  String url;
  String user;
  String? pass;
  String? rigId;

  factory Pool.fromJson(Map<String, dynamic> json, MinerBinary minerBinary) {
    for (final key in ["url", "user"]) {
      if (!json.containsKey(key) || json[key] == null || json[key].isEmpty) {
        throw FormatException("Ensure $key exist and not empty or null");
      }
    }
    if (json["algo"] != null) {
      if ((minerBinary == MinerBinary.xmrig ||
              minerBinary == MinerBinary.xmrigCC) &&
          !Constants.supportedXmrigAlgo.contains(json["algo"])) {
        throw FormatException(
            "Ensure algo is supported by ${minerBinary.name}");
      }
      if (minerBinary == MinerBinary.ccminer &&
          !Constants.supportedCCMinerAlgo.contains(json["algo"])) {
        throw FormatException(
            "Ensure algo is supported by ${minerBinary.name}");
      }
    }
    Pool pool = Pool(
      algo: json["algo"],
      url: json["url"],
      user: json["user"],
      pass: json["pass"],
      rigId: json["rig-id"],
    );
    return pool;
  }

  Map<String, dynamic> toJson() => {
        "algo": algo,
        "url": url,
        "user": user,
        "pass": pass,
        "rig-id": rigId,
      };
}

class UsersMinerConfig {
  UsersMinerConfig(
      {required this.minerConfig,
      required this.minerConfigMd5,
      this.timeStamp,
      this.minerBinary});

  Map<String, dynamic> minerConfig;
  String minerConfigMd5;
  int? timeStamp;
  MinerBinary? minerBinary;

  factory UsersMinerConfig.fromJson(Map<String, dynamic> json) =>
      UsersMinerConfig(
          minerConfig: json["minerConfig"],
          timeStamp: json["timeStamp"],
          minerConfigMd5: json["minerConfigMd5"],
          minerBinary:
              MinerBinary.values.byName(json["minerBinary"] ?? "xmrig"));

  Map<String, dynamic> toJson() => {
        "minerConfig": minerConfig,
        "timeStamp": timeStamp,
        "minerConfigMd5": minerConfigMd5,
        "minerBinary": minerBinary
      };
}
