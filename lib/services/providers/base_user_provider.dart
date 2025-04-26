import 'package:flutter/foundation.dart';

class BaseUserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userSettings;
  List<Map<String, dynamic>>? _unreadNotifications;
  int _unreadMessageCount = 0;
  List<Map<String, dynamic>>? _workoutPlans;
  List<Map<String, dynamic>>? _mealPlans;

  // Getters
  Map<String, dynamic>? get userData => _userData;
  Map<String, dynamic>? get userSettings => _userSettings;
  List<Map<String, dynamic>>? get unreadNotifications => _unreadNotifications;
  int get unreadMessageCount => _unreadMessageCount;
  List<Map<String, dynamic>>? get workoutPlans => _workoutPlans;
  List<Map<String, dynamic>>? get mealPlans => _mealPlans;

  // Setters
  void setUserData(Map<String, dynamic>? data) {
    _userData = data;
    if (data == null) {
      clearAllData();
    }
    notifyListeners();
  }

  void setUserSettings(Map<String, dynamic> settings) {
    _userSettings = settings;
    notifyListeners();
  }

  void setUnreadNotifications(List<Map<String, dynamic>> notifications) {
    _unreadNotifications = notifications;
    notifyListeners();
  }

  void setUnreadMessageCount(int count) {
    _unreadMessageCount = count;
    notifyListeners();
  }

  void setWorkoutPlans(List<Map<String, dynamic>> plans) {
    _workoutPlans = plans;
    notifyListeners();
  }

  void setMealPlans(List<Map<String, dynamic>> plans) {
    _mealPlans = plans;
    notifyListeners();
  }

  void clearAllData() {
    _userData = null;
    _userSettings = null;
    _unreadNotifications = null;
    _unreadMessageCount = 0;
    _workoutPlans = null;
    _mealPlans = null;
    notifyListeners();
  }
} 