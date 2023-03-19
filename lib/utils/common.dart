import 'dart:io';
import 'dart:math';

import 'package:ekatapoolcompanion/models/logtext.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:system_info2/system_info2.dart';

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }

  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }

  return MaterialColor(color.value, swatch);
}

String getReadableHashrateString(double hashrate) {
  List<String> byteUnits = <String>["H", "KH", "MH", "GH", "TH", "PH"];
  int i = 0;
  while (hashrate > 1000) {
    hashrate = hashrate / 1000;
    i++;
  }
  return '${hashrate.toStringAsFixed(2)} ${byteUnits[i]} /s';
}

String getReadableCoins(String coins, int coinUnits, [String withSymbol = '']) {
  String amount = (int.parse(coins) / coinUnits)
      .toStringAsFixed(coinUnits.toString().length - 1);
  return '$amount $withSymbol';
}

// TODO: Depending on usage we might be able to move this function
//  to own module
int calculateSharesDiffPercent(int difficulty, int shares,
    bool slushMiningEnabled, int blockTime, int weight) {
  double accurateShares = shares.toDouble();
  if (slushMiningEnabled) {
    accurateShares = shares /
        (1 /
            blockTime *
            (weight - weight * pow(e, ((blockTime * -1) / weight))));
  }
  if (difficulty > accurateShares) {
    return 100 - (accurateShares / difficulty * 100).round();
  }
  return (100 - (difficulty / accurateShares * 100).round()) * -1;
}

String timeStringFromSecond(int valueInSeconds) {
  int day = valueInSeconds ~/ (24 * 60 * 60);
  int remainingSeconds = valueInSeconds - (day * 24 * 60 * 60);
  int hours = remainingSeconds ~/ (60 * 60);
  int minutes = (remainingSeconds - (hours * 60 * 60)) ~/ 60;
  int seconds = remainingSeconds - (hours * 60 * 60) - (minutes * 60);
  String result = "${day}d:${hours}h:${minutes}m:${seconds}s";
  return result;
}

String convertByteToGB(int bytes) {
  return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
}

Future<String?> getGPUVendor() async {
  if (Platform.isLinux) {
    var result = await Process.run("lspci", []);
    var vgaInfos = result.stdout
        .split("\n")
        .where((r) => r.toString().toLowerCase().contains("vga"));
    if (vgaInfos.join().toLowerCase().contains("nvidia")) {
      return "nvidia";
    }
    if (vgaInfos.join().toLowerCase().contains("amd")) {
      return "amd";
    }
  }
  if (Platform.isWindows) {
    var result = await Process.run(
        "wmic", ["path", "win32_VideoController", "get", "name"]);
    if (result.stdout
        .split("\n")
        .where((r) => r.toString().toLowerCase().contains("nvidia"))
        .isNotEmpty) {
      return "nvidia";
    }
    if (result.stdout
        .split("\n")
        .where((r) => r.toString().toLowerCase().contains("amd"))
        .isNotEmpty) {
      return "amd";
    }
  }
  return null;
}

Future<bool> ensureCUDALoaderExist() async {
  var cudaLoaderPath = path.join(Directory.current.path,
      "bin/${Platform.isLinux ? "libxmrig-cuda.so" : "xmrig-cuda.dll"}");
  return await File(cudaLoaderPath).exists();
}

// CoinData? getCoinDataFromMinerConfig(MinerConfig? minerConfig) {
//   if (minerConfig != null && minerConfig.pools.isNotEmpty) {
//     final poolHost = minerConfig.pools.first.url;
//     final coinDataList = coinDatas.where((coinData) {
//       final coinPools = coinData.coinPools.where((coinPool) =>
//           ("${coinPool.poolAddress}:${coinPool.poolPortCPU}" == poolHost) ||
//           ("${coinPool.poolAddress}:${coinPool.poolPortGPU}" == poolHost));
//       if (coinPools.isNotEmpty) {
//         return true;
//       }
//       return false;
//     });
//     if (coinDataList.isNotEmpty) {
//       return coinDataList.first;
//     }
//   }
//   return null;
// }

Map<String, dynamic> getSystemInfo() {
  final systemInfo = {
    "platform": Platform.operatingSystem,
    "osInfo": {
      "name": SysInfo.operatingSystemName,
      "version": SysInfo.operatingSystemVersion,
      "kernelVersion": SysInfo.kernelVersion
    },
    "totalPhysicalMemory":
        "${(SysInfo.getTotalPhysicalMemory() / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB",
  };
  final cpuInfos = [];
  for (final core in SysInfo.cores) {
    cpuInfos.add({
      "vendor": core.vendor,
      "name": core.name,
      "socket": core.socket.toString(),
      "architecture": core.architecture.name
    });
  }
  if (cpuInfos.isNotEmpty) systemInfo["cpuInfos"] = cpuInfos;
  return systemInfo;
}

//NOTE: Not happy with this, need to refactor
List<List<LogText>> formatLogs(String rawString) {
  final List<List<LogText>> logTexts = [];
  final logChunks = rawString.split("\u001b[0m");
  for (final logChunk in logChunks) {
    final List<LogText> logText = [];
    RegExp re = RegExp(r"(\u001b\[\d+[;\d]*m)(.*)");
    if (re.hasMatch(logChunk)) {
      var text = "";
      var fgColor = Colors.white;
      var bgColor = Colors.transparent;
      var isBold = false;
      final decorationStrings = [];
      final matches = re.allMatches(logChunk);
      decorationStrings.add(matches.first.group(1));
      if (matches.first.group(2) != null &&
          matches.first.group(2)!.startsWith("\u001b")) {
        final newMatches = re.allMatches(matches.first.group(2)!);
        decorationStrings.add(newMatches.first.group(1));
        text = newMatches.first.group(2) ?? "";
      } else {
        text = matches.first.group(2) ?? "";
      }
      for (final decorationString in decorationStrings) {
        final mapping =
            Constants.ansiColorMapping[decorationString.split("\u001b[")[1]];
        if (mapping != null) {
          if (mapping["isBg"] as bool) {
            bgColor = mapping["color"] as Color;
          } else {
            fgColor = mapping["color"] as Color;
            isBold = mapping["isBold"] as bool;
          }
        }
      }
      logChunk.split(RegExp(r"(\u001b\[\d+[;\d]*m)")).forEach((element) {
        if (element.isNotEmpty) {
          if (element.trim() == text.trim()) {
            logText.add(LogText(
                text: text.trim(),
                logFormatDecoration: LogTextDecoration(
                    fgColor: fgColor, bgColor: bgColor, isBold: isBold)));
          } else {
            logText.add(LogText(
                text: element.trim(),
                logFormatDecoration: LogTextDecoration(
                    fgColor: Colors.white,
                    bgColor: Colors.transparent,
                    isBold: false)));
          }
        }
      });
    } else {
      logText.add(LogText(
          text: logChunk.trim(),
          logFormatDecoration: LogTextDecoration(
              fgColor: Colors.white,
              bgColor: Colors.transparent,
              isBold: false)));
    }
    logTexts.add(logText);
  }
  return logTexts;
}

Future<String> getPackageVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

Future<String> saveMinerConfigToFile(String config) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = await File("${directory.path}/epc_xmrig_config.json")
      .writeAsString(config);
  return file.path;
}
