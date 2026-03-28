import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _keyUseKg = 'useKg';
  static const _keyNotifications = 'notificationsEnabled';

  bool _useKg = true;
  bool _notificationsEnabled = true;

  bool get useKg => _useKg;
  bool get notificationsEnabled => _notificationsEnabled;

  SettingsService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _useKg = prefs.getBool(_keyUseKg) ?? true;
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
    notifyListeners();
  }

  Future<void> setUseKg(bool value) async {
    if (_useKg == value) return;
    _useKg = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseKg, value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  String formatWeight(double kg) {
    if (_useKg) return '${kg % 1 == 0 ? kg.toInt() : kg} kg';
    final lb = kg * 2.20462;
    final rounded = (lb * 4).round() / 4;
    return '${rounded % 1 == 0 ? rounded.toInt() : rounded} lb';
  }

  String get weightUnit => _useKg ? 'kg' : 'lb';

  double toDisplayWeight(double kg) =>
      _useKg ? kg : double.parse((kg * 2.20462).toStringAsFixed(2));

  double toKg(double displayWeight) =>
      _useKg ? displayWeight : displayWeight / 2.20462;
}
