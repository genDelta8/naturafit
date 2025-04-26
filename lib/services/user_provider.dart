import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  // Add new state variable
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userSettings;
  Map<String, String>? _inviteData;
  List<Map<String, dynamic>>? _partiallyTotalClients;
  List<Map<String, dynamic>>? _partiallyTotalProfessionals;
  List<Map<String, dynamic>>? _workoutPlans;
  List<Map<String, dynamic>>? _mealPlans;
  List<Map<String, dynamic>>? _unreadNotifications;
  List<Map<String, dynamic>>? _currentWeekSlots;
  List<Map<String, dynamic>>? _currentWeekAvailableSlots;
  List<Map<String, dynamic>>? _availableFutureSlots;
  List<Map<String, dynamic>>? _todaySlots;
  int? _totalClientsCount;
  int _unreadMessageCount = 0;
  List<Map<String, dynamic>>? _threeUpcomingSessions;
  Map<String, dynamic>? _trainerNextSession;
  Map<String, dynamic>? _trainerNextAvailableSession;
  List<Map<String, dynamic>>? _progressLogs;
  Map<String, dynamic>? _latestMeasurements;
  List<String>? _unlockedAchievements;
  DateTime? _lastAchievementCheck;
  Map<String, dynamic>? _currentWeightGoal;

  // Add getter
  Map<String, dynamic>? get userData => _userData;
  Map<String, dynamic>? get userSettings => _userSettings;
  Map<String, String>? get inviteData => _inviteData;
  List<Map<String, dynamic>>? get partiallyTotalClients =>
      _partiallyTotalClients;
  List<Map<String, dynamic>>? get partiallyTotalProfessionals =>
      _partiallyTotalProfessionals;
  List<Map<String, dynamic>>? get workoutPlans => _workoutPlans;
  List<Map<String, dynamic>>? get mealPlans => _mealPlans;
  List<Map<String, dynamic>>? get unreadNotifications => _unreadNotifications;
  List<Map<String, dynamic>>? get currentWeekSlots => _currentWeekSlots;
  List<Map<String, dynamic>>? get currentWeekAvailableSlots => _currentWeekAvailableSlots;
  List<Map<String, dynamic>>? get availableFutureSlots => _availableFutureSlots;
  List<Map<String, dynamic>>? get todaySlots => _todaySlots;
  int? get totalClientsCount => _totalClientsCount;
  int get unreadMessageCount => _unreadMessageCount;
  List<Map<String, dynamic>>? get threeUpcomingSessions =>
      _threeUpcomingSessions;
  Map<String, dynamic>? get trainerNextSession => _trainerNextSession;
  Map<String, dynamic>? get trainerNextAvailableSession => _trainerNextAvailableSession;
  List<Map<String, dynamic>>? get progressLogs => _progressLogs;
  Map<String, dynamic>? get latestMeasurements => _latestMeasurements;
  List<String>? get unlockedAchievements => _unlockedAchievements;
  DateTime? get lastAchievementCheck => _lastAchievementCheck;
  Map<String, dynamic>? get currentWeightGoal => _currentWeightGoal;

  void setUserData(Map<String, dynamic>? data) {
    _userData = data;
    if (data == null) {
      // Clear invite data when user data is cleared
      _inviteData = null;
      _partiallyTotalClients = null;
      _partiallyTotalProfessionals = null;
      _workoutPlans = null;
      _mealPlans = null;
      _unreadNotifications = null;
      _currentWeekSlots = null;
      _currentWeekAvailableSlots = null;
      _availableFutureSlots = null;
      _todaySlots = null;
      _threeUpcomingSessions = null;
      _unreadMessageCount = 0;
      _totalClientsCount = 0;
      _userSettings = null;
      _userData = null;
      _inviteData = null;
      _trainerNextSession = null;
      _trainerNextAvailableSession = null;
      _unlockedAchievements = null;
      _lastAchievementCheck = null;
      _currentWeightGoal = null;
    }
    notifyListeners();
  }

//SETTERS
  void setPartiallyTotalClients(List<Map<String, dynamic>> clients) {
    _partiallyTotalClients = clients;
    notifyListeners();
  }

  void setPartiallyTotalProfessionals(
      List<Map<String, dynamic>> professionals) {
    _partiallyTotalProfessionals = professionals;
    notifyListeners();
  }

  void setWorkoutPlans(List<Map<String, dynamic>> workoutPlans) {
    _workoutPlans = workoutPlans;
    notifyListeners();
  }

  void setMealPlans(List<Map<String, dynamic>> mealPlans) {
    _mealPlans = mealPlans;
    notifyListeners();
  }

  void setUnreadNotifications(List<Map<String, dynamic>> notifications) {
    _unreadNotifications = notifications;
    notifyListeners();
  }

  void setInviteData(Map<String, String> data) {
    _inviteData = data;
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

  void setCurrentWeekSlots(List<Map<String, dynamic>> slots) {
    _currentWeekSlots = slots;
    notifyListeners();
  }

  void setCurrentWeekAvailableSlots(List<Map<String, dynamic>> slots) {
    _currentWeekAvailableSlots = slots;
    notifyListeners();
  }

  void setAvailableFutureSlots(List<Map<String, dynamic>> slots) {
    _availableFutureSlots = slots;
    notifyListeners();
  }

  void setTodaySlots(List<Map<String, dynamic>> slots) {
    _todaySlots = slots;
    notifyListeners();
  }

  void setTotalClientsCount(int count) {
    _totalClientsCount = count;
    notifyListeners();
  }

  void setUnreadMessageCount(int count) {
    _unreadMessageCount = count;
    notifyListeners();
  }

  void setThreeUpcomingSessions(List<Map<String, dynamic>> sessions) {
    _threeUpcomingSessions = sessions;
    notifyListeners();
  }

  void setTrainerNextSession(Map<String, dynamic>? session) {
    _trainerNextSession = session;
    notifyListeners();
  }

  void setTrainerNextAvailableSession(Map<String, dynamic>? session) {
    _trainerNextAvailableSession = session;
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

  void setUnlockedAchievements(List<String> achievements) {
    _unlockedAchievements = achievements;
    notifyListeners();
  }

  void setCurrentWeightGoal(Map<String, dynamic>? goal) {
    _currentWeightGoal = goal;
    notifyListeners();
  }

/*
  void clearInviteData() {
    _inviteData = null;
    notifyListeners();
  }
  */

//REFRESH FUNCTIONS
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


  addAvailableFutureSlots(Map<String, dynamic> slots) {
    List<Map<String, dynamic>> currentAvailableFutureSlots = List<Map<String, dynamic>>.from(availableFutureSlots ?? []);
    currentAvailableFutureSlots.add(slots);
    setAvailableFutureSlots(currentAvailableFutureSlots);
  }

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
    debugPrint('Clearing all data');
    _inviteData = null;
    _partiallyTotalClients = null;
    _partiallyTotalProfessionals = null;
    _workoutPlans = null;
    _mealPlans = null;
    _unreadNotifications = null;
    _currentWeekSlots = null;
    _currentWeekAvailableSlots = null;
    _availableFutureSlots = null;
    _todaySlots = null;
    _userSettings = null;
    _threeUpcomingSessions = null;
    _unreadMessageCount = 0;
    _totalClientsCount = 0;
    _userData = null;
    _trainerNextSession = null;
    _trainerNextAvailableSession = null;
    _progressLogs = null;
    _latestMeasurements = null;
    _unlockedAchievements = null;
    _lastAchievementCheck = null;
    _currentWeightGoal = null;
    notifyListeners();
  }

  Future<void> updateMealPlan(String trainerId, String professionalRole, Map<String, dynamic> planData) async {
    final planId = planData['planId'];
    if (_userData != null && _userData!['meals'] != null) {
      final mealsList = List<Map<String, dynamic>>.from(_userData!['meals']);
      final index = mealsList.indexWhere((meal) => meal['planId'] == planId);
      if (index != -1) {
        mealsList[index] = planData;
        setUserData({..._userData!, 'meals': mealsList});
      }
    }
  }

  Future<void> refreshAchievements() async {
    final userData = _userData;
    if (userData == null) return;

    final userId = userData['userId'];
    try {
      final achievementsDoc = await FirebaseFirestore.instance
          .collection('user_achievements')
          .doc(userId)
          .get();

      if (achievementsDoc.exists) {
        final achievements = List<String>.from(
            achievementsDoc.data()?['unlockedAchievements'] ?? []);
        _unlockedAchievements = achievements;
        _lastAchievementCheck = achievementsDoc.data()?['lastUpdated']?.toDate();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing achievements: $e');
    }
  }

  Future<void> unlockAchievement(String achievementId) async {
    final userData = _userData;
    if (userData == null) return;

    final userId = userData['userId'];
    try {
      final currentAchievements = List<String>.from(_unlockedAchievements ?? []);
      if (!currentAchievements.contains(achievementId)) {
        currentAchievements.add(achievementId);
        
        await FirebaseFirestore.instance
            .collection('user_achievements')
            .doc(userId)
            .set({
          'unlockedAchievements': currentAchievements,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _unlockedAchievements = currentAchievements;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  bool hasAchievement(String achievementId) {
    return _unlockedAchievements?.contains(achievementId) ?? false;
  }
}
