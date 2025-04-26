import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/services/achievement_service.dart';

class DataFetchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchUserData(String userId, String role, BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await Future.wait([
        _fetchConnectionData(userId, role, userProvider),
        _fetchWorkoutPlans(userId, role, userProvider),
        _fetchMealPlans(userId, role, userProvider),
        _fetchUnreadNotifications(userId, userProvider),
        _fetchUnreadMessageCount(userId, userProvider),
        if (role == 'trainer' || role == 'dietitian') ...[
          fetchProfessionalSlots(userId, role, userProvider),
          if (role == 'trainer') ...[
            _fetchTrainerNextSession(userId, userProvider),
            _fetchTrainerNextAvailableSession(userId, userProvider),
          ],
        ]
        else if (role == 'client') ...[
          _fetchClientSessions(userId, userProvider),
          _fetchClientProgressLogs(userId, userProvider),
          _checkProfileCompletion(userId, userProvider),
          _fetchLatestWeightGoal(userId, userProvider),
        ],
      ]);
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      // Continue execution even if fetch fails
    }
  }

  Future<void> _fetchConnectionData(String userId, String role, UserProvider userProvider) async {
    try {
      if (role == 'trainer' || role == 'dietitian') {
        final clientsSnapshot = await _firestore
            .collection('connections')
            .doc(role)
            .collection(userId)
            .where('status', whereIn: [
              fbClientConfirmedStatus,
              fbCreatedStatusForAppUser,
              fbClientRejectedStatus,
              fbCreatedStatusForNotAppUser])
            .get();

        final activeAndPendingClients = clientsSnapshot.docs.map((doc) => doc.data()).toList();
        userProvider.setPartiallyTotalClients(activeAndPendingClients);
        
        /*
        final totalClientsSnapshot = await _firestore
            .collection('connections')
            .doc(role)
            .collection(userId)
            .where('status', whereIn: ['active', 'completed'])
            .count()
            .get();

        userProvider.setTotalClientsCount(totalClientsSnapshot.count ?? 0);
        debugPrint('Total clients (active + completed): ${totalClientsSnapshot.count}');
        */

      } else if (role == 'client') {
        final professionalsSnapshot = await _firestore
            .collection('connections')
            .doc('client')
            .collection(userId)
            .where('status', whereIn: [fbClientConfirmedStatus, fbCreatedStatusForAppUser])
            .get();

        final activeProfessionals = professionalsSnapshot.docs.map((doc) => doc.data()).toList();
        userProvider.setPartiallyTotalProfessionals(activeProfessionals);
        debugPrint('Found ${activeProfessionals.length} active professionals');

        final userData = userProvider.userData;
        final clientProfileImageUrl = userData?['clientProfileImageUrl'] ?? '';
        final clientFullName = userData?['clientFullName'] ?? '';

        // Update lastActivity for each professional's connection
        for (var professional in activeProfessionals) {
          final professionalId = professional['professionalId'];
          final professionalRole = professional['professionalRole'];
          
          if (professionalId != null && professionalRole != null) {
            await _firestore
                .collection('connections')
                .doc(professionalRole)
                .collection(professionalId)
                .doc(userId)
                .update({
                  'clientProfileImageUrl': clientProfileImageUrl,
                  'clientFullName': clientFullName,
                  'lastActivity': FieldValue.serverTimestamp(),
                });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching connection data: $e');
      rethrow;
    }
  }
  

  Future<void> _fetchWorkoutPlans(String userId, String role, UserProvider userProvider) async {
    try {
      debugPrint('Fetching workout plans for $role');
      final collection = (role == 'client') ? 'clients' : 'trainers';

      
      // For clients, fetch plans with status 'active', 'pending', or 'current'
      final Query query = _firestore
          .collection('workouts')
          .doc(collection)
          .collection(userId);

      final QuerySnapshot workoutPlansSnapshot = await query.where('status', whereIn: ['active', 'pending', 'current', 'confirmed', 'template']).get();

      final workoutPlans = workoutPlansSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
          
      userProvider.setWorkoutPlans(workoutPlans);
      debugPrint('Found ${workoutPlans.length} workout plans for $role');
    } catch (e) {
      debugPrint('Error fetching workout plans: $e');
      rethrow;
    }
  }

  Future<void> _fetchMealPlans(String userId, String role, UserProvider userProvider) async {
    try {
      debugPrint('Fetching meal plans for $role');
      final collectionDoc = (role == 'client') ? 'clients' : ((role == 'trainer') ? 'trainers' : 'dietitians');
      
      final Query query = _firestore
          .collection('meals')
          .doc(collectionDoc)
          .collection(userId);

      // For clients, fetch plans with status 'active', 'pending', or 'current'
      final QuerySnapshot mealPlansSnapshot = await query.where('status', whereIn: ['active', 'pending', 'current', 'confirmed', 'template']).get();

      final mealPlans = mealPlansSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
          
      userProvider.setMealPlans(mealPlans);
      debugPrint('Found ${mealPlans.length} meal plans for $role');
    } catch (e) {
      debugPrint('Error fetching meal plans: $e');
      rethrow;
    }
  }

  Future<void> fetchProfessionalSlots(String userId, String role, UserProvider userProvider) async {
    try {
      final now = DateTime.now();
      
      
      
      
      debugPrint('Fetching professional slots for $role');
      final collectionDoc = (role == 'trainer') ? 'trainer_sessions' : 'dietitian_sessions';
      final collectionRef = (role == 'trainer') ? 'allTrainerSessions' : 'allDietitianSessions';

      // Reference to trainer_sessions collection
      final professionalSessionRef = _firestore
          .collection(collectionDoc)
          .doc(userId)
          .collection(collectionRef);

      

      // Fetch upcoming sessions (next 3 booked or confirmed sessions)
      final threeUpcomingSessionsSnapshot = await professionalSessionRef
          .where('sessionDate', isGreaterThanOrEqualTo: now)
          .where('status', whereIn: ['booked', 'confirmed', 'pending', 'group', 'cancelled', 'requested', 'active'])
          .orderBy('sessionDate')
          .limit(3)
          .get();

      final threeUpcomingSessions = threeUpcomingSessionsSnapshot.docs
          .map((doc) => doc.data())
          .where((session) => 
            session['status'] != 'available' // Exclude available slots
          )
          .toList();

      // Fetch available future slots and group sessions
      final availableSlotsSnapshot = await professionalSessionRef
          .where('sessionDate', isGreaterThanOrEqualTo: now)
          .where('status', whereIn: ['available', 'group', 'requested', 'active'])
          .orderBy('sessionDate')
          .get();

      final availableSlots = availableSlotsSnapshot.docs
          .map((doc) => doc.data())
          .where((slot) => 
            slot['status'] == 'available' ||
            slot['scheduleType'] == 'group' ||
            slot['status'] == 'requested'
          )
          .toList();

      // Update UserProvider
      
      userProvider.setThreeUpcomingSessions(threeUpcomingSessions);
      userProvider.setAvailableFutureSlots(availableSlots);

      
      debugPrint('Found ${threeUpcomingSessions.length} upcoming sessions');
      debugPrint('Found ${availableSlots.length} available/group slots');
    } catch (e) {
      debugPrint('Error fetching professional slots: $e');
      rethrow;
    }
  }

  Future<void> _fetchUnreadNotifications(String userId, UserProvider userProvider) async {
    try {
      final unreadNotificationsSnapshot = await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('allNotifications')
          .where('read', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final unreadNotifications = unreadNotificationsSnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'notificationId': doc.id,
              })
          .toList();

      userProvider.setUnreadNotifications(unreadNotifications);
      debugPrint('Found ${unreadNotifications.length} unread notifications');
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<void> _fetchUnreadMessageCount(String userId, UserProvider userProvider) async {
    try {
      final unreadMessagesSnapshot = await _firestore
          .collection('messages')
          .doc(userId)
          .collection('last_messages')
          .where('read', isEqualTo: false)
          .count()
          .get();

      userProvider.setUnreadMessageCount(unreadMessagesSnapshot.count ?? 0);
      debugPrint('Unread message count: ${unreadMessagesSnapshot.count}');
    } catch (e) {
      debugPrint('Error fetching unread message count: $e');
      rethrow;
    }
  }

  Future<void> _fetchClientSessions(String userId, UserProvider userProvider) async {
    try {
      final now = DateTime.now();
      
      // Get current week's start and end
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 7));
      
      final startOfWeek = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
      final endOfWeek = DateTime(currentWeekEnd.year, currentWeekEnd.month, currentWeekEnd.day);

      // Reference to client_sessions collection
      final clientSessionsRef = _firestore
          .collection('client_sessions')
          .doc(userId)
          .collection('allClientSessions');

      // Fetch current week's sessions
      final currentWeekSnapshot = await clientSessionsRef
          .where('sessionDate', isGreaterThanOrEqualTo: startOfWeek)
          .where('sessionDate', isLessThan: endOfWeek)
          .orderBy('sessionDate')
          .get();

      final currentWeekSessions = currentWeekSnapshot.docs
          .map((doc) => doc.data())
          .toList();


      
      // Fetch upcoming sessions (next 3)
      final upcomingSessionsSnapshot = await clientSessionsRef
          .where('sessionDate', isGreaterThanOrEqualTo: now)
          .orderBy('sessionDate')
          .limit(3)
          .get();

      final upcomingSessions = upcomingSessionsSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      

      // Update UserProvider
      userProvider.setCurrentWeekSlots(currentWeekSessions);
      userProvider.setThreeUpcomingSessions(upcomingSessions);

      debugPrint('Found ${currentWeekSessions.length} sessions for current week');
      debugPrint('Found ${upcomingSessions.length} upcoming sessions');
    } catch (e) {
      debugPrint('Error fetching client sessions: $e');
      rethrow;
    }
  }

  Future<void> _fetchTrainerNextSession(String userId, UserProvider userProvider) async {
    try {
      final now = DateTime.now();
      
      final nextSessionSnapshot = await _firestore
          .collection('trainer_sessions')
          .doc(userId)
          .collection('allTrainerSessions')
          .where('sessionDate', isGreaterThanOrEqualTo: now)
          .where('status', whereIn: ['booked', 'confirmed', 'active', 'group', 'pending'])
          .orderBy('sessionDate')
          .limit(1)
          .get();

      if (nextSessionSnapshot.docs.isNotEmpty) {
        final nextSession = nextSessionSnapshot.docs.first.data();
        userProvider.setTrainerNextSession(nextSession);
        debugPrint('Next trainer session found: ${nextSession['sessionDate']}');
      } else {
        userProvider.setTrainerNextSession(null);
        debugPrint('No upcoming sessions found for trainer');
      }
    } catch (e) {
      debugPrint('Error fetching next trainer session: $e');
      rethrow;
    }
  }

  Future<void> _fetchTrainerNextAvailableSession(String userId, UserProvider userProvider) async {
    try {
      final now = DateTime.now();
      
      final nextAvailableSessionSnapshot = await _firestore
          .collection('trainer_sessions')
          .doc(userId)
          .collection('allTrainerSessions')
          .where('sessionDate', isGreaterThanOrEqualTo: now)
          .where('status', whereIn: ['available', 'group'])
          .orderBy('sessionDate')
          .limit(1)
          .get();

      if (nextAvailableSessionSnapshot.docs.isNotEmpty) {
        final nextAvailableSession = nextAvailableSessionSnapshot.docs.first.data();
        userProvider.setTrainerNextAvailableSession(nextAvailableSession);
        debugPrint('Next available trainer session found: ${nextAvailableSession['sessionDate']}');
      } else {
        userProvider.setTrainerNextAvailableSession(null);
        debugPrint('No upcoming available sessions found for trainer');
      }
    } catch (e) {
      debugPrint('Error fetching next available trainer session: $e');
      rethrow;
    }
  }

  Future<void> _fetchClientProgressLogs(String userId, UserProvider userProvider) async {
    try {
      final progressLogsSnapshot = await _firestore
          .collection('progress_logs')
          .doc(userId)
          .collection('all_progress_logs')
          .orderBy('date', descending: true)
          .get();

      final progressLogs = progressLogsSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      userProvider.setProgressLogs(progressLogs);
      debugPrint('Found ${progressLogs.length} progress logs');

      // Calculate latest measurements if logs exist
      if (progressLogs.isNotEmpty) {
        final latestLog = progressLogs.first;
        debugPrint('Latest log: $latestLog');
        userProvider.setLatestMeasurements(latestLog);
      }
    } catch (e) {
      debugPrint('Error fetching progress logs: $e');
      rethrow;
    }
  }

  Future<void> _checkProfileCompletion(String userId, UserProvider userProvider) async {
    try {
      final userData = userProvider.userData;
      if (userData == null) return;

      final achievementService = AchievementService(
        userProvider: userProvider,
        userId: userId,
      );

      await achievementService.checkProfileAchievements(
        profileData: userData,
      );
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
    }
  }

  Future<void> _fetchLatestWeightGoal(String userId, UserProvider userProvider) async {
    try {
      final weightGoalsSnapshot = await _firestore
          .collection('weight_goals')
          .doc(userId)
          .collection('all_weight_goals')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (weightGoalsSnapshot.docs.isNotEmpty) {
        final latestWeightGoal = weightGoalsSnapshot.docs.first.data();
        userProvider.setCurrentWeightGoal(latestWeightGoal);
        debugPrint('Latest weight goal fetched: $latestWeightGoal');
      } else {
        userProvider.setCurrentWeightGoal(null);
        debugPrint('No weight goals found for user');
      }
    } catch (e) {
      debugPrint('Error fetching latest weight goal: $e');
      rethrow;
    }
  }
}