import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PriceProvider extends ChangeNotifier {
  late SharedPreferences _prefs;

  final Map<String, double> _prices = {
    'pc': 1000,
    'ps4': 1500,
    'game': 5000,
    'cake': 10000,
    'soda': 5000,
    'hype': 15000,
  };

  Map<String, double> get prices => _prices;

  PriceProvider() {
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    _prefs = await SharedPreferences.getInstance();
    _prices.forEach((key, value) {
      _prices[key] = _prefs.getDouble('price_$key') ?? value;
    });
    notifyListeners();
  }

  Future<void> updatePrice(String key, double value) async {
    _prices[key] = value;
    await _prefs.setDouble('price_$key', value);
    notifyListeners();
  }
}
