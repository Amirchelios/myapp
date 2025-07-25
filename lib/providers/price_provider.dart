import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_models.dart';

class PriceProvider with ChangeNotifier {
  Price _price = Price();

  Price get price => _price;

  PriceProvider() {
    loadPrice();
  }

  Future<void> loadPrice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final priceString = prefs.getString('price');
      if (priceString != null && priceString.isNotEmpty) {
        _price = Price.fromJson(jsonDecode(priceString));
      }
    } catch (e) {
      // Handle error
    }
    notifyListeners();
  }

  Future<void> savePrice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('price', jsonEncode(_price.toJson()));
    } catch (e) {
      // Handle error
    }
  }

  void setPrice(Price newPrice) {
    _price = newPrice;
    savePrice();
    notifyListeners();
  }
}
