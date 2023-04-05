import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UiStateProvider extends ChangeNotifier {
  bool _showBottomNavbar = false;
  int _bottomNavigationIndex = 0;
  bool _minerConfigPageShowMinerEngineSelect = false;
  int _colorSchemeIndex = 28;
  ThemeMode _themeMode = ThemeMode.system;

  bool get showBottomNavbar => _showBottomNavbar;

  int get bottomNavigationIndex => _bottomNavigationIndex;

  bool get minerConfigPageShowMinerEngineSelect =>
      _minerConfigPageShowMinerEngineSelect;

  int get colorSchemeIndex => _colorSchemeIndex;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadThemeConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString("THEME_MODE");
    final colorSchemeIndex = prefs.getInt("COLOR_SCHEME_INDEX");
    if (themeMode != null) {
      switch (themeMode) {
        case "light":
          _themeMode = ThemeMode.light;
          break;
        case "dark":
          _themeMode = ThemeMode.dark;
          break;
        case "system":
          _themeMode = ThemeMode.system;
          break;
        default:
          _themeMode = ThemeMode.system;
          break;
      }
    }
    if (colorSchemeIndex != null) {
      _colorSchemeIndex = colorSchemeIndex;
    }
  }

  set showBottomNavbar(bool showBottomNavbar) {
    _showBottomNavbar = showBottomNavbar;
    notifyListeners();
  }

  set bottomNavigationIndex(int bottomNavigationIndex) {
    _bottomNavigationIndex = bottomNavigationIndex;
    notifyListeners();
  }

  set minerConfigPageShowMinerEngineSelect(
      bool minerConfigPageShowMinerEngineSelect) {
    _minerConfigPageShowMinerEngineSelect =
        minerConfigPageShowMinerEngineSelect;
    notifyListeners();
  }

  Future<void> setColorSchemeIndex(int colorSchemeIndex) async {
    _colorSchemeIndex = colorSchemeIndex;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("COLOR_SCHEME_INDEX", colorSchemeIndex);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("THEME_MODE", themeMode.name);
  }
}
