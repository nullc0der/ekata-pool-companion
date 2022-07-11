import 'package:ekatapoolcompanion/models/poolstat.dart';
import 'package:flutter/material.dart';

class PoolStatProvider extends ChangeNotifier {
  PoolStat? _poolStat;

  PoolStat? get poolStat => _poolStat;

  set poolStat(PoolStat? newPoolStat) {
    _poolStat = newPoolStat;
    notifyListeners();
  }
}
