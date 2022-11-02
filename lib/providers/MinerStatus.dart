import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:flutter/foundation.dart';

class MinerStatusProvider extends ChangeNotifier {
  CoinData? _coinData;
  bool _isMining = false;
  bool _startMiningPressed = false;
  String _walletAddress = "";

  bool get isMining => _isMining;
  bool get startMiningPressed => _startMiningPressed;
  CoinData? get coinData => _coinData;
  String get walletAddress => _walletAddress;

  set isMining(bool isMiningStatus) {
    _isMining = isMiningStatus;
    notifyListeners();
  }

  set startMiningPressed(bool newStartMiningStatus) {
    _startMiningPressed = newStartMiningStatus;
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
}
