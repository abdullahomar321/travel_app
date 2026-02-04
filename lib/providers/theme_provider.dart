import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Default Cobalt Blue
  static const Color defaultPrimaryColor = Color(0xFF0047AB);
  static const Color defaultSecondaryColor = Color(0xFF002E6D);

  Color _primaryColor = defaultPrimaryColor;
  Color _secondaryColor = defaultSecondaryColor;

  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    int? colorValue = prefs.getInt('primaryColor');
    if (colorValue != null) {
      _setThemeColors(Color(colorValue));
    }
  }

  void setTheme(Color color) async {
    _setThemeColors(color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.value);
    notifyListeners();
  }

  void _setThemeColors(Color color) {
    _primaryColor = color;
    // Generate a darker shade for the gradient/secondary color
    HSVColor hsv = HSVColor.fromColor(color);
    _secondaryColor = hsv.withValue((hsv.value - 0.2).clamp(0.0, 1.0)).toColor();
  }
}
