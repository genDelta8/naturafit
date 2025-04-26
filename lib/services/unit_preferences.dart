import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnitPreferences extends ChangeNotifier {
  static const String _isMetricKey = 'isMetric';
  bool _isMetric = true;

  UnitPreferences() {
    _loadPreferences();
  }

  bool get isMetric => _isMetric;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isMetric = prefs.getBool(_isMetricKey) ?? true; // Default to metric
    notifyListeners();
  }

  Future<void> toggleUnit() async {
    final prefs = await SharedPreferences.getInstance();
    _isMetric = !_isMetric;
    await prefs.setBool(_isMetricKey, _isMetric);
    notifyListeners();
  }

  // Conversion helpers
  double kgToLbs(double kg) => kg * 2.20462;
  double lbsToKg(double lbs) => lbs / 2.20462;
  
  double cmToInch(double cm) => cm / 2.54;
  double inchToCm(double inch) => inch * 2.54;

  double cmToft(double cm) => cm / 30.48;
  double ftToCm(double ft) => ft * 30.48;

  // Add new conversion helpers
  double gToOz(double grams) => (grams / 28.3495);
  double ozToG(double ounces) => ounces * 28.3495;

  // Format weight based on current unit
  String formatWeight(double weight) {
    if (_isMetric) {
      return '${weight.toStringAsFixed(1)} kg';
    } else {
      return '${kgToLbs(weight).toStringAsFixed(1)} lbs';
    }
  }

  // Format height based on current unit
  String formatHeight(double heightCm) {
    if (_isMetric) {
      return '${heightCm.toStringAsFixed(1)} cm';
    } else {
      final inches = cmToInch(heightCm);
      final feet = (inches / 12).floor();
      final remainingInches = (inches % 12).round();
      return "$feet'$remainingInches\"";
    }
  }

  // Format serving size based on current unit
  String formatServing(double amount, String unit) {
    if (unit == 'pc') return '$amount pc'; // Return as is for pieces
    
    if (unit == 'g') {
      if (_isMetric) {
        return '${amount.toStringAsFixed(1)} g';
      } else {
        return '${gToOz(amount).toStringAsFixed(1)} oz';
      }
    }
    
    return '$amount $unit'; // For other units
  }

  // Get multiplier for nutrient calculations
  double getServingMultiplier(double quantity, String originalUnit) {
    if (originalUnit == 'g' && !_isMetric) {
      // Convert input ounces to grams for calculation
      return ozToG(quantity);
    }
    return quantity;
  }
} 