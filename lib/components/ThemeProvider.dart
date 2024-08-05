import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  late ThemeData _currentTheme;
  final String key = "theme";
  SharedPreferences? _prefs;

  ThemeNotifier() {
    _currentTheme = lightTheme;
    _loadFromPrefs();
  }

  ThemeData get currentTheme => _currentTheme;

  void toggleTheme() {
    _currentTheme = (_currentTheme == lightTheme) ? darkTheme : lightTheme;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    final isDark = _prefs!.getBool(key) ?? false;
    _currentTheme = isDark ? darkTheme : lightTheme;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    await _initPrefs();
    await _prefs!.setBool(key, _currentTheme == darkTheme);
  }
}

final lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue,
  scaffoldBackgroundColor: Colors.white,
  cardColor: Colors.white,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
  ),
  iconTheme: const IconThemeData(color: Colors.blue),
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.blueAccent,
  scaffoldBackgroundColor: Colors.grey[900],
  cardColor: Colors.grey[800],
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
  ),
  iconTheme: const IconThemeData(color: Colors.blueAccent),
);
