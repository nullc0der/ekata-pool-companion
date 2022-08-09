import 'package:flutter/foundation.dart';

class MinerStatusProvider extends ChangeNotifier {
  bool _isMining = false;

  bool get isMining => _isMining;

  set isMining(bool isMiningStatus) {
    _isMining = isMiningStatus;
    notifyListeners();
  }
}
