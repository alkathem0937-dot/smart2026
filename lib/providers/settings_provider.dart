import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import '../config/api_config.dart';

/// Settings Provider - manages app settings using SharedPreferences
class SettingsProvider with ChangeNotifier {
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyDarkMode = 'dark_mode_enabled';
  static const String _keyLanguage = 'language';
  
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'ar';
  
  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  String get language => _language;
  
  /// Initialize settings from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
      _darkModeEnabled = prefs.getBool(_keyDarkMode) ?? false;
      _language = prefs.getString(_keyLanguage) ?? 'ar';
      notifyListeners();
      developer.log('Settings initialized: notifications=$_notificationsEnabled, darkMode=$_darkModeEnabled, language=$_language', name: 'SettingsProvider');
    } catch (e) {
      developer.log('Error initializing settings: $e', name: 'SettingsProvider');
    }
  }
  
  /// Toggle notifications
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotifications, value);
      developer.log('Notifications setting saved: $value', name: 'SettingsProvider');
    } catch (e) {
      developer.log('Error saving notifications setting: $e', name: 'SettingsProvider');
    }
  }
  
  /// Toggle dark mode
  Future<void> setDarkModeEnabled(bool value) async {
    _darkModeEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDarkMode, value);
      developer.log('Dark mode setting saved: $value', name: 'SettingsProvider');
    } catch (e) {
      developer.log('Error saving dark mode setting: $e', name: 'SettingsProvider');
    }
  }
  
  /// Set language
  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, value);
      developer.log('Language setting saved: $value', name: 'SettingsProvider');
    } catch (e) {
      developer.log('Error saving language setting: $e', name: 'SettingsProvider');
    }
  }
  
  /// Clear all local data
  Future<void> clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedApi = prefs.getString(ApiConfig.prefsKeyApiBaseUrl);
      await prefs.clear();
      if (savedApi != null && savedApi.isNotEmpty) {
        await prefs.setString(ApiConfig.prefsKeyApiBaseUrl, savedApi);
      }
      await ApiConfig.initialize();
      // Reset to defaults
      _notificationsEnabled = true;
      _darkModeEnabled = false;
      _language = 'ar';
      notifyListeners();
      developer.log('Local data cleared', name: 'SettingsProvider');
    } catch (e) {
      developer.log('Error clearing local data: $e', name: 'SettingsProvider');
      rethrow;
    }
  }
}

