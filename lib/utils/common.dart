import 'dart:math';

import 'package:flutter/material.dart';

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
