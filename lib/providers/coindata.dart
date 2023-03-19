import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:flutter/material.dart';

class CoinDataProvider extends ChangeNotifier {
  List<CoinData> _coinDatas = [];
  CoinData? _selectedCoinData;
  String? _selectedPoolName;
  String? _selectedRegion;
  String? _selectedPoolUrl;
  int? _selectedPoolPort;

  List<CoinData> get coinDatas => _coinDatas;

  CoinData? get selectedCoinData => _selectedCoinData;

  String? get selectedPoolName => _selectedPoolName;

  String? get selectedRegion => _selectedRegion;

  String? get selectedPoolUrl => _selectedPoolUrl;

  int? get selectedPoolPort => _selectedPoolPort;

  set coinDatas(List<CoinData> coinDatas) {
    _coinDatas = coinDatas;
    notifyListeners();
  }

  set selectedCoinData(CoinData? coinData) {
    _selectedCoinData = coinData;
    notifyListeners();
  }

  set selectedPoolName(String? poolName) {
    _selectedPoolName = poolName;
    notifyListeners();
  }

  set selectedRegion(String? region) {
    _selectedRegion = region;
    notifyListeners();
  }

  set selectedPoolUrl(String? poolUrl) {
    _selectedPoolUrl = poolUrl;
    notifyListeners();
  }

  set selectedPoolPort(int? poolPort) {
    _selectedPoolPort = poolPort;
    notifyListeners();
  }

  void addCoinDatas(List<CoinData> coinDatas) {
    _coinDatas.addAll(coinDatas);
    notifyListeners();
  }
}
