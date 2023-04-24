import 'dart:convert';
import 'dart:io';

import 'package:ekatapoolcompanion/models/ccminersummary.dart';
import 'package:ekatapoolcompanion/models/minersummary.dart';
import 'package:http/http.dart' as http;

class MinerSummaryService {
  Future<MinerSummary> getMinerSummary() async {
    try {
      final response =
          await http.get(Uri.parse("http://127.0.0.1:45580/2/summary"));
      if (response.statusCode == 200) {
        return minerSummaryFromJson(response.body);
      }
      throw Exception("Failed to fetch miner summary");
    } on Exception {
      throw Exception("Failed to fetch miner summary");
    }
  }
}

class CCMinerSummaryService {
  Socket? _socket;
  static final CCMinerSummaryService _instance = CCMinerSummaryService._();

  static CCMinerSummaryService get instance => _instance;

  CCMinerSummaryService._();

  CCMinerSummary _getSummary(String data) {
    CCMinerSummary ccMinerSummary = CCMinerSummary(
        algo: "",
        currentHash: "",
        solved: "",
        accepted: "",
        rejected: "",
        diff: "",
        uptime: "");
    if (data[data.length - 1] == "|") {
      data = data.substring(0, data.length - 1);
    }
    final List<String> splittedDatas = data.split(";");
    for (final splittedData in splittedDatas) {
      final chunks = splittedData.split("=");
      if (chunks.first == "ALGO") {
        ccMinerSummary.algo = chunks.last;
      }
      if (chunks.first == "KHS") {
        ccMinerSummary.currentHash = chunks.last;
      }
      if (chunks.first == "SOLV") {
        ccMinerSummary.solved = chunks.last;
      }
      if (chunks.first == "ACC") {
        ccMinerSummary.accepted = chunks.last;
      }
      if (chunks.first == "REJ") {
        ccMinerSummary.rejected = chunks.last;
      }
      if (chunks.first == "DIFF") {
        ccMinerSummary.diff = chunks.last;
      }
      if (chunks.first == "UPTIME") {
        ccMinerSummary.uptime = chunks.last;
      }
    }
    return ccMinerSummary;
  }

  Future<void> _connect(void Function(CCMinerSummary) onSummary) async {
    _socket = await Socket.connect('127.0.0.1', 44690);
    _socket?.listen((event) {
      final data = utf8.decode(event);
      onSummary(_getSummary(data));
    });
  }

  Future<void> getSummary(void Function(CCMinerSummary) onSummary) async {
    await _connect(onSummary);
    _socket?.write("summary");
    _disconnect();
  }

  void _disconnect() {
    _socket?.close();
  }
}
