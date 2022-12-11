// NOTE: CPU Thread: Xmrig need thread option set per algo basis on config file
// so once user selects the coin we need to set thread option based on its algo,
// for now if user provides this in config.json it will be used, otherwise if
// user defines through thread count input it will pass the value as command line
// arg instead, cmd line arg don't need it per algo basis

// TODO: Based on GPU availability backend should be selected

import 'dart:convert';

import 'package:ekatapoolcompanion/utils/constants.dart';

MinerConfig minerConfigFromJson(String str) =>
    MinerConfig.fromJson(json.decode(str));

String minerConfigToJson(MinerConfig data, {bool prettyPrint = false}) {
  if (prettyPrint) {
    var encoder = JsonEncoder.withIndent(" " * 2);
    return encoder.convert(data.toJson());
  }
  return json.encode(data.toJson());
}

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

  factory MinerConfig.fromJson(Map<String, dynamic> json) {
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
      pools: List<Pool>.from(json["pools"].map((x) => Pool.fromJson(x))),
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

  factory Pool.fromJson(Map<String, dynamic> json) {
    for (final key in ["url", "user"]) {
      if (!json.containsKey(key) || json[key] == null || json[key].isEmpty) {
        throw FormatException("Ensure $key exist and not empty or null");
      }
    }
    if (json["algo"] != null) {
      if (!Constants.supportedAlgo.contains(json["algo"])) {
        throw const FormatException("Ensure algo is valid");
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
