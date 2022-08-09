import 'package:ekatapoolcompanion/models/minersummary.dart';
import 'package:flutter/material.dart';

class MinerSummaryProvider extends ChangeNotifier {
  MinerSummary? _minerSummary;

  MinerSummary? get minerSummary => _minerSummary;

  set minerSummary(MinerSummary? newMinerSummary) {
    _minerSummary = newMinerSummary;
    notifyListeners();
  }
}
