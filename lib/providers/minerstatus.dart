import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:flutter/foundation.dart';

class MinerStatusProvider extends ChangeNotifier {
  CoinData? _coinData;
  bool _isMining = false;
  bool _showMinerScreen = false;
  String _walletAddress = "";
  int? _threadCount;
  Map<String, dynamic> _currentlyMining = {
    "coinData": null,
    "walletAddress": ""
  };

  bool get isMining => _isMining;
  bool get showMinerScreen => _showMinerScreen;
  CoinData? get coinData => _coinData;
  String get walletAddress => _walletAddress;
  int? get threadCount => _threadCount;
  Map<String, dynamic> get currentlyMining => _currentlyMining;

  set isMining(bool isMiningStatus) {
    _isMining = isMiningStatus;
    notifyListeners();
  }

  set showMinerScreen(bool newShowMinerScreenStatus) {
    _showMinerScreen = newShowMinerScreenStatus;
    notifyListeners();
  }

  set coinData(CoinData? selectedCoinData) {
    _coinData = selectedCoinData;
    notifyListeners();
  }

  set walletAddress(String newWalletAddress) {
    _walletAddress = newWalletAddress;
    notifyListeners();
  }

  set threadCount(int? newThreadCount) {
    _threadCount = newThreadCount;
    notifyListeners();
  }

  set currentlyMining(Map<String, dynamic> newCurrentlyMining) {
    _currentlyMining = newCurrentlyMining;
    notifyListeners();
  }
}
