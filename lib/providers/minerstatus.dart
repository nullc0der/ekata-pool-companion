import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:flutter/foundation.dart';

class MinerStatusProvider extends ChangeNotifier {
  CoinData? _coinData;
  bool _isMining = false;
  int? _threadCount;
  int? _currentThreadCount;
  MinerConfig? _minerConfig;
  MinerConfig? _currentlyMiningMinerConfig;
  String? _gpuVendor;
  String? _minerConfigPath;
  int _sendNextHeartBeatInSeconds = Constants.initialHeartBeatInSeconds;

  bool get isMining => _isMining;
  CoinData? get coinData => _coinData;
  int? get threadCount => _threadCount;
  int? get currentThreadCount => _currentThreadCount;
  String? get gpuVendor => _gpuVendor;
  MinerConfig? get minerConfig => _minerConfig;
  MinerConfig? get currentlyMiningMinerConfig => _currentlyMiningMinerConfig;
  String? get minerConfigPath => _minerConfigPath;
  int get sendNextHeartBeatInSeconds => _sendNextHeartBeatInSeconds;

  set isMining(bool isMiningStatus) {
    _isMining = isMiningStatus;
    notifyListeners();
  }

  set coinData(CoinData? selectedCoinData) {
    _coinData = selectedCoinData;
    notifyListeners();
  }

  set threadCount(int? newThreadCount) {
    _threadCount = newThreadCount;
    notifyListeners();
  }

  set currentThreadCount(int? threadCount) {
    _currentThreadCount = threadCount;
    notifyListeners();
  }

  set gpuVendor(String? gpuVendor) {
    _gpuVendor = gpuVendor;
    notifyListeners();
  }

  set minerConfig(MinerConfig? minerConfig) {
    _minerConfig = minerConfig;
    notifyListeners();
  }

  set currentlyMiningMinerConfig(MinerConfig? minerConfig) {
    _currentlyMiningMinerConfig = minerConfig;
    notifyListeners();
  }

  set minerConfigPath(String? minerConfigPath) {
    _minerConfigPath = minerConfigPath;
    notifyListeners();
  }

  set sendNextHeartBeatInSeconds(int nextHeartBeatInSeconds) {
    _sendNextHeartBeatInSeconds = nextHeartBeatInSeconds;
    notifyListeners();
  }
}
