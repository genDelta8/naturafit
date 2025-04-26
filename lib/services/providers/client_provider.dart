/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ClientProvider extends ChangeNotifier {
  // Basic user data
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userSettings;
  List<Map<String, dynamic>>? _unreadNotifications;
  int _unreadMessageCount = 0;
  List<Map<String, dynamic>>? _workoutPlans;
  List<Map<String, dynamic>>? _mealPlans;

  // Client specific data
  List<Map<String, dynamic>>? _partiallyTotalProfessionals;
  List<Map<String, dynamic>>? _currentWeekSlots;
  List<Map<String, dynamic>>? _threeUpcomingSessions;
  List<Map<String, dynamic>>? _progressLogs;
  Map<String, dynamic>? _latestMeasurements;

  // Basic getters
  Map<String, dynamic>? get userData => _userData;
  Map<String, dynamic>? get userSettings => _userSettings;
  List<Map<String, dynamic>>? get unreadNotifications => _unreadNotifications;
  int get unreadMessageCount => _unreadMessageCount;
  List<Map<String, dynamic>>? get workoutPlans => _workoutPlans;
  List<Map<String, dynamic>>? get mealPlans => _mealPlans;

  // Client specific getters
  List<Map<String, dynamic>>? get partiallyTotalProfessionals => _partiallyTotalProfessionals;
  List<Map<String, dynamic>>? get currentWeekSlots => _currentWeekSlots;
  List<Map<String, dynamic>>? get threeUpcomingSessions => _threeUpcomingSessions;
  List<Map<String, dynamic>>? get progressLogs => _progressLogs;
  Map<String, dynamic>? get latestMeasurements => _latestMeasurements;

  // Basic setters
  void setUserData(Map<String, dynamic>? data) {
    _userData = data;
    if (data == null) {
      clearAllData();
    }
    notifyListeners();
  }

  Future<void> setUserSettings(Map<String, dynamic> settings) async {
    final userData = _userData;
    if (userData == null) {
      debugPrint('Error: User data is null. Cannot set user settings.');
      return;
    }

    final userId = userData['userId'];

    try {
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(userId)
          .set(settings, SetOptions(merge: true));

      // Update local state
      _userSettings = settings;
      notifyListeners();

      debugPrint('User settings updated: $settings');
    } catch (e) {
      debugPrint('Error setting user settings: $e');
    }
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

  // Client specific setters
  void setPartiallyTotalProfessionals(List<Map<String, dynamic>> professionals) {
    _partiallyTotalProfessionals = professionals;
    notifyListeners();
  }

  void setCurrentWeekSlots(List<Map<String, dynamic>> slots) {
    _currentWeekSlots = slots;
    notifyListeners();
  }

  void setThreeUpcomingSessions(List<Map<String, dynamic>> sessions) {
    _threeUpcomingSessions = sessions;
    notifyListeners();
  }

  void setProgressLogs(List<Map<String, dynamic>> logs) {
    _progressLogs = logs;
    notifyListeners();
  }

  void setLatestMeasurements(Map<String, dynamic> measurements) {
    _latestMeasurements = measurements;
    notifyListeners();
  }




//REFRESH FUNCTIONS
/*
  addManualPartiallyTotalClient(
      String userId, String role, Map<String, dynamic> addedClientData) async {
// Get current clients list from UserProvider
    debugPrint('Getting current clients list');
    final currentClients =
        List<Map<String, dynamic>>.from(partiallyTotalClients ?? []);

    // Add new client to the list
    currentClients.add(addedClientData);

    // Update UserProvider with new list
    setPartiallyTotalClients(currentClients);

    debugPrint('Current clients list updated: $currentClients');
  }
*/

  addMealPlan(
      String userId, String role, Map<String, dynamic> addedMealData) async {
// Get current clients list from UserProvider

    final currentMeals = List<Map<String, dynamic>>.from(mealPlans ?? []);

    // Add new client to the list
    currentMeals.add(addedMealData);

    // Update UserProvider with new list
    setMealPlans(currentMeals);

    debugPrint('Current meals list updated: $currentMeals');
  }

  addWorkoutPlan(
      String userId, Map<String, dynamic> addedWorkoutData) async {
    final currentWorkouts = List<Map<String, dynamic>>.from(workoutPlans ?? []);
    currentWorkouts.add(addedWorkoutData);
    setWorkoutPlans(currentWorkouts);
    debugPrint('Current workouts list updated: $currentWorkouts');
  }

  addThreeUpcomingSessions(Map<String, dynamic> addedSessionData) {
    List<Map<String, dynamic>> currentThreeUpcomingSessions =
        List<Map<String, dynamic>>.from(threeUpcomingSessions ?? []);


debugPrint('Adding upcoming session to user provider: $addedSessionData');

    currentThreeUpcomingSessions.add(addedSessionData);
    currentThreeUpcomingSessions
        .sort((a, b) => a['sessionDate'].compareTo(b['sessionDate']));
    if (currentThreeUpcomingSessions.length > 3) {
      currentThreeUpcomingSessions = currentThreeUpcomingSessions.sublist(0, 3);
      setThreeUpcomingSessions(currentThreeUpcomingSessions);
    } else {
      setThreeUpcomingSessions(currentThreeUpcomingSessions);
    }
  }

/*
  addAvailableFutureSlots(Map<String, dynamic> slots) {
    List<Map<String, dynamic>> currentAvailableFutureSlots = List<Map<String, dynamic>>.from(availableFutureSlots ?? []);
    currentAvailableFutureSlots.add(slots);
    setAvailableFutureSlots(currentAvailableFutureSlots);
  }
*/

  Future<void> refreshUserSettings() async {
    final userData = _userData;
    if (userData == null) return;

    final userId = userData['userId'];

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('settings')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        _userSettings = docSnapshot.data();
        debugPrint('User settings refreshed: $_userSettings');
      } else {
        debugPrint('User settings not found for userId: $userId');
      }
    } catch (e) {
      debugPrint('Error refreshing user settings: $e');
    }

    notifyListeners();
  }

  Future<void> refreshWorkoutPlans() async {
    final userData = _userData;
    if (userData == null) return;

    final userId = userData['userId'];
    final role = userData['role'];

    try {
      final collection = (role == 'client') ? 'clients' : 'trainers';
      final snapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .doc(collection)
          .collection(userId)
          .get();

      final plans = snapshot.docs.map((doc) => doc.data()).toList();
      setWorkoutPlans(plans);
      debugPrint('Workout plans refreshed: ${plans.length} plans found');
    } catch (e) {
      debugPrint('Error refreshing workout plans: $e');
    }
  }

  Future<void> refreshMealPlans() async {
    final userData = _userData;
    if (userData == null) return;

    final userId = userData['userId'];
    final role = userData['role'];

    try {
      final collection = (role == 'client')
          ? 'clients'
          : ((role == 'trainer') ? 'trainers' : 'dietitians');
      final snapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(collection)
          .collection(userId)
          .get();

      final plans = snapshot.docs.map((doc) => doc.data()).toList();
      setMealPlans(plans);
      debugPrint('Meal plans refreshed: ${plans.length} plans found');
    } catch (e) {
      debugPrint('Error refreshing meal plans: $e');
    }
  }

  void clearAllData() {
    _userData = null;
    _userSettings = null;
    _unreadNotifications = null;
    _unreadMessageCount = 0;
    _workoutPlans = null;
    _mealPlans = null;
    _partiallyTotalProfessionals = null;
    _currentWeekSlots = null;
    _threeUpcomingSessions = null;
    _progressLogs = null;
    _latestMeasurements = null;
    notifyListeners();
  }
} 
*/