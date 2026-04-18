import 'package:flutter/foundation.dart';

import '../models/inheritance_models.dart';
import '../services/api_service.dart';

class InheritanceProvider with ChangeNotifier {
  final ApiService _api;

  InheritanceProvider({ApiService? apiService}) : _api = apiService ?? ApiService();

  bool _isLoading = false;
  String? _error;
  InheritanceResult? _result;

  bool get isLoading => _isLoading;
  String? get error => _error;
  InheritanceResult? get result => _result;

  double _sumMoney(Iterable<String> values) {
    double sum = 0;
    for (final v in values) {
      final cleaned = v.trim().replaceAll(',', '');
      final d = double.tryParse(cleaned);
      if (d != null && d.isFinite && d > 0) {
        sum += d;
      }
    }
    return sum;
  }

  Future<void> calculate({
    required List<EstateItemInput> estateItems,
    required List<DebtItemInput> debtItems,
    required List<BequestItemInput> bequestItems,
    required List<HeirInput> heirs,
  }) async {
    _isLoading = true;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      final estateTotal = _sumMoney(estateItems.map((e) => e.value));
      final debtsTotal = _sumMoney(debtItems.map((d) => d.amount));
      final bequestsTotal = _sumMoney(bequestItems.map((b) => b.amount));

      final body = {
        'estate_value': estateTotal.toStringAsFixed(2),
        'debts': debtsTotal.toStringAsFixed(2),
        'bequests': bequestsTotal.toStringAsFixed(2),
        'estate_items': estateItems.map((e) => e.toJson()).toList(),
        'debt_items': debtItems.map((e) => e.toJson()).toList(),
        'bequest_items': bequestItems.map((e) => e.toJson()).toList(),
        'heirs': heirs.map((h) => h.toJson()).toList(),
      };

      final data = await _api.post('/api/inheritance/calculate/', body);
      _result = InheritanceResult.fromJson(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _error = null;
    _result = null;
    notifyListeners();
  }
}
