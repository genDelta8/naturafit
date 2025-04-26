class MeasurementConverter {
  static double convert(double value, String fromUnit, String toUnit) {
    double baseValue = toBase(value, fromUnit);
    return fromBase(baseValue, toUnit);
  }

  static double toBase(double value, String fromUnit) {
    switch (fromUnit) {
      case 'cm':
        return value;
      case 'm':
        return value * 100;
      case 'ft':
        return value * 30.48;
      case 'in':
        return value * 2.54;
      case 'kg':
        return value;
      case 'lbs':
        return value * 0.453592;
      default:
        return value;
    }
  }

  static double fromBase(double baseValue, String toUnit) {
    switch (toUnit) {
      case 'cm':
        return baseValue;
      case 'm':
        return baseValue / 100;
      case 'ft':
        return baseValue / 30.48;
      case 'in':
        return baseValue / 2.54;
      case 'kg':
        return baseValue;
      case 'lbs':
        return baseValue / 0.453592;
      default:
        return baseValue;
    }
  }

  static Map<String, Map<String, double>> get unitRanges => {
    'cm': {'min': 0, 'max': 300, 'interval': 1},
    'm': {'min': 0, 'max': 3, 'interval': 0.01},
    'ft': {'min': 0, 'max': 10, 'interval': 0.1},
    'in': {'min': 0, 'max': 120, 'interval': 1},
    'kg': {'min': 0, 'max': 200, 'interval': 1},
    'lbs': {'min': 0, 'max': 440, 'interval': 1},
  };
} 