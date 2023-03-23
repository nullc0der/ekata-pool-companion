import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:flutter/material.dart';

class CoinDataProvider extends ChangeNotifier {
  // TODO: There are some properties which are same as MinerStatusProvider,
  // This was done so CoinDataProvider data don't go outside of CoinData Widget
  // At some point, remove duplicate properties from one provider and let all
  // widget use from same provider
  List<CoinData> _coinDatas = [];
  CoinData? _selectedCoinData;
  String? _selectedPoolName;
  String? _selectedRegion;
  String? _selectedPoolUrl;
  int? _selectedPoolPort;
  String _walletAddress = "";
  int? _threadCount;
  MinerBinary _selectedMinerBinary = MinerBinary.xmrig;
  String? _xmrigCCServerUrl;
  String? _xmrigCCServerToken;
  String? _xmrigCCWorkerId;
  String? _password;
  String? _rigId;

  List<CoinData> get coinDatas => _coinDatas;

  CoinData? get selectedCoinData => _selectedCoinData;

  String? get selectedPoolName => _selectedPoolName;

  String? get selectedRegion => _selectedRegion;

  String? get selectedPoolUrl => _selectedPoolUrl;

  int? get selectedPoolPort => _selectedPoolPort;

  String get walletAddress => _walletAddress;

  int? get threadCount => _threadCount;

  MinerBinary get selectedMinerBinary => _selectedMinerBinary;

  String? get xmrigCCServerUrl => _xmrigCCServerUrl;

  String? get xmrigCCServerToken => _xmrigCCServerToken;

  String? get xmrigCCWorkerId => _xmrigCCWorkerId;

  String? get password => _password;

  String? get rigId => _rigId;

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

  set walletAddress(String walletAddress) {
    _walletAddress = walletAddress;
    notifyListeners();
  }

  set threadCount(int? newThreadCount) {
    _threadCount = newThreadCount;
    notifyListeners();
  }

  set selectedMinerBinary(MinerBinary selectedMinerBinary) {
    _selectedMinerBinary = selectedMinerBinary;
    notifyListeners();
  }

  set xmrigCCServerUrl(String? xmrigCCServerUrl) {
    _xmrigCCServerUrl = xmrigCCServerUrl;
    notifyListeners();
  }

  set xmrigCCServerToken(String? xmrigCCServerToken) {
    _xmrigCCServerToken = xmrigCCServerToken;
    notifyListeners();
  }

  set xmrigCCWorkerId(String? xmrigCCWorkerId) {
    _xmrigCCWorkerId = xmrigCCWorkerId;
    notifyListeners();
  }

  set password(String? password) {
    _password = password;
    notifyListeners();
  }

  set rigId(String? rigId) {
    _rigId = rigId;
    notifyListeners();
  }

  void addCoinDatas(List<CoinData> coinDatas) {
    _coinDatas.addAll(coinDatas);
    notifyListeners();
  }
}
