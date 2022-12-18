import 'package:flutter/foundation.dart';

class UiStateProvider extends ChangeNotifier {
  bool _showBottomNavbar = false;
  int _bottomNavigationIndex = 0;

  bool get showBottomNavbar => _showBottomNavbar;
  int get bottomNavigationIndex => _bottomNavigationIndex;

  set showBottomNavbar(bool showBottomNavbar) {
    _showBottomNavbar = showBottomNavbar;
    notifyListeners();
  }

  set bottomNavigationIndex(int bottomNavigationIndex) {
    _bottomNavigationIndex = bottomNavigationIndex;
    notifyListeners();
  }
}
