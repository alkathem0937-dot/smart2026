import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Local lookup data service – stores case types/subtypes and governorates/courts
/// locally (SharedPreferences) with ability to sync from API.
class LocalLookupService {
  static const _kCaseSubtypes = 'local_case_subtypes';
  static const _kGovernorates = 'local_governorates';

  // ────────────── Default Case Types & Subtypes ──────────────

  static const List<String> caseTypes = [
    'مدنية',
    'جزائية',
    'شخصية',
    'إدارية',
    'تجارية',
    'تنفيذ',
  ];

  static const Map<String, List<String>> _defaultSubtypes = {
    'مدنية': ['ضريبية', 'جمركية', 'زكوية', 'مدنية', 'مستعجل'],
    'جزائية': ['تعرض للانحراف', 'جسيمة', 'غير جسيمة', 'مستعجلة'],
    'شخصية': ['شخصية', 'مستعجل'],
    'إدارية': ['إدارية', 'مستعجل', 'عمالية'],
    'تجارية': ['تجارية', 'مستعجل'],
    'تنفيذ': ['إدارية', 'أوامر', 'مستعجل', 'تجارية', 'شخصية', 'عمالية', 'جنائية', 'مدنية'],
  };

  /// Returns subtypes for a given main case type (local, possibly overridden).
  static Future<List<String>> getSubtypes(String caseType) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCaseSubtypes);
    if (raw != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(raw);
        if (map.containsKey(caseType)) {
          return List<String>.from(map[caseType]);
        }
      } catch (_) {}
    }
    return _defaultSubtypes[caseType] ?? [];
  }

  /// Save subtypes fetched from network.
  static Future<void> saveSubtypes(Map<String, List<String>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCaseSubtypes, jsonEncode(data));
  }

  // ────────────── Governorates & Courts ──────────────

  /// Returns cached governorates list (each has id, name, courts[]).
  static Future<List<Map<String, dynamic>>> getGovernorates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGovernorates);
    if (raw != null) {
      try {
        final List list = jsonDecode(raw);
        return list.cast<Map<String, dynamic>>();
      } catch (_) {}
    }
    return [];
  }

  /// Get courts for a specific governorate from local cache.
  static Future<List<Map<String, dynamic>>> getCourts(int governorateId) async {
    final govs = await getGovernorates();
    final gov = govs.firstWhere(
      (g) => g['id'] == governorateId,
      orElse: () => <String, dynamic>{},
    );
    if (gov.isNotEmpty && gov['courts'] != null) {
      return List<Map<String, dynamic>>.from(
        (gov['courts'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    return [];
  }

  /// Save governorates list to local storage.
  static Future<void> saveGovernorates(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGovernorates, jsonEncode(data));
  }

  // ────────────── Sync from API ──────────────

  /// Sync governorates (+ nested courts) from the server and cache locally.
  static Future<List<Map<String, dynamic>>> syncGovernorates(ApiService api) async {
    try {
      final dynamic response = await api.getGovernorates();
      List<dynamic> items;
      if (response is List) {
        items = response;
      } else if (response is Map) {
        items = (response['results'] as List?) ??
            (response['data'] is List ? response['data'] as List : []);
        if (items.isEmpty && response['data'] is Map) {
          items = (response['data']['results'] as List?) ?? [];
        }
      } else {
        items = [];
      }

      final mapped = items.map<Map<String, dynamic>>((e) {
        return {
          'id': e['id'],
          'name': e['name'] ?? '',
          'courts': (e['courts'] as List?)
                  ?.map((c) => {'id': c['id'], 'name': c['name'] ?? c['court_name'] ?? ''})
                  .toList() ??
              [],
        };
      }).toList();

      await saveGovernorates(mapped);
      return mapped;
    } catch (_) {
      return await getGovernorates();
    }
  }
}
