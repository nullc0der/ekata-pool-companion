import 'package:ekatapoolcompanion/models/ccminersummary.dart';
import 'package:ekatapoolcompanion/models/minersummary.dart';
import 'package:flutter/material.dart';

class MinerSummaryProvider extends ChangeNotifier {
  MinerSummary? _minerSummary;
  CCMinerSummary? _ccMinerSummary;

  MinerSummary? get minerSummary => _minerSummary;

  CCMinerSummary? get ccMinerSummary => _ccMinerSummary;

  set minerSummary(MinerSummary? newMinerSummary) {
    _minerSummary = newMinerSummary;
    notifyListeners();
  }

  set ccMinerSummary(CCMinerSummary? ccMinerSummary) {
    _ccMinerSummary = ccMinerSummary;
    notifyListeners();
  }
}
