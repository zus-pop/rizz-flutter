import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rizz_mobile/theme/theme.dart';

class AppSettingProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  ThemeData _themeData = lightMode;

  AppSettingProvider() {
    _initializeData();
  }

  ThemeData get themeData => _themeData;

  Future<void> _initializeData() async {
    final theme = await _secureStorage.read(key: "theme");
    if (theme != null) {
      themeData = theme == "light" ? lightMode : darkMode;
      notifyListeners(); // Notify listeners after data is loaded
    }
  }

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
      _secureStorage.write(key: "theme", value: 'dark');
    } else {
      themeData = lightMode;
      _secureStorage.write(key: "theme", value: 'light');
    }
  }
}
