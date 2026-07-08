import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  late bool _isDarkMode;
  late String _themeAccent;

  ThemeProvider(this._storageService) {
    _isDarkMode = _storageService.isDarkMode();
    _themeAccent = _storageService.getThemeAccent();
  }

  bool get isDarkMode => _isDarkMode;
  String get themeAccent => _themeAccent;

  Color get primaryAccent {
    switch (_themeAccent.toLowerCase()) {
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'teal':
        return const Color(0xFF14B8A6);
      case 'orange':
        return const Color(0xFFF97316);
      case 'violet':
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _storageService.setDarkMode(_isDarkMode);
  }

  void setThemeAccent(String accent) async {
    _themeAccent = accent;
    notifyListeners();
    await _storageService.setThemeAccent(accent);
  }
}
