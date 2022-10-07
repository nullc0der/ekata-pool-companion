import 'package:ekatapoolcompanion/models/poolstat.dart';
import 'package:flutter/material.dart';

class PoolStatProvider extends ChangeNotifier {
  PoolStat? _poolStat;
  bool _hasFetchError = false;

  PoolStat? get poolStat => _poolStat;
  bool get hasFetchError => _hasFetchError;

  set poolStat(PoolStat? newPoolStat) {
    _poolStat = newPoolStat;
    notifyListeners();
  }

  set hasFetchError(bool newHasFetchError) {
    _hasFetchError = newHasFetchError;
    notifyListeners();
  }
}
