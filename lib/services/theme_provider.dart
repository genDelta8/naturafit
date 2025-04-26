import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';
  bool _isDarkMode = false;
  bool _isToggling = false;
  
  bool get isDarkMode => _isDarkMode;

  // Add duration property for animation
  static const Duration themeAnimationDuration = Duration(milliseconds: 600);
  static const Curve themeAnimationCurve = Curves.easeInOut;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_isToggling) return;
    
    _isToggling = true;
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, _isDarkMode);
    } finally {
      await Future.delayed(themeAnimationDuration);
      _isToggling = false;
    }
  }
} 