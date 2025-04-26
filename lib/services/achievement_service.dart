import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/models/achievements/client_achievements.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AchievementService {
  final UserProvider userProvider;
  final String userId;

  AchievementService({
    required this.userProvider,
    required this.userId,
  });

  // Check workout-related achievements
  Future<void> checkWorkoutAchievements({
    required List<Map<String, dynamic>> exercises,
    required Map<String, List<bool>> completedSets,
    required Duration workoutDuration,
    required Map<String, List<TextEditingController>> weightControllers,
    bool isEarlyBird = false,
  }) async {
    await Future.wait([
      _checkWorkoutCompletionAchievements(exercises, completedSets),
      _checkWorkoutTimeAchievements(workoutDuration, isEarlyBird),
      checkStrengthAchievements(
        exercises: exercises,
        completedSets: completedSets,
        weightControllers: weightControllers,
      ),
      _checkExerciseVarietyAchievements(exercises),
    ]);
  }

  // Check progress-related achievements
  Future<void> checkProgressAchievements({
    required double? weightLoss,
    required double? bodyFatReduction,
    required double? muscleGain,
    required bool hasProgressPhotos,
    required int daysSinceLastProgress,
  }) async {
    await Future.wait([
      _checkWeightLossAchievements(weightLoss),
      _checkBodyCompositionAchievements(bodyFatReduction, muscleGain),
      _checkTrackingAchievements(hasProgressPhotos, daysSinceLastProgress),
    ]);
  }

  // Check profile-related achievements
  Future<void> checkProfileAchievements({
    required Map<String, dynamic> profileData,
  }) async {
    await _checkSocialAchievements(profileData);
  }

  // Check plan completion achievements
  Future<void> checkPlanAchievements({
    required String planId,
    required bool isCompleted,
  }) async {
    await _checkWorkoutPlanAchievements(planId, isCompleted);
  }

  // Check feedback achievements
  Future<void> checkFeedbackAchievements(Map<String, Map<String, dynamic>> exerciseFeedbacks) async {
    try {
      // Get user's feedback history
      final doc = await FirebaseFirestore.instance
          .collection('achievement_progress')
          .doc(userId)
          .get();

      // Get or create set of exercises user has provided feedback for
      final feedbackExercises = Set<String>.from(
        doc.data()?['feedbackExercises'] ?? [],
      );

      // Track if any detailed feedback was provided in this session
      bool hasDetailedFeedback = false;

      // Add new exercises with feedback to the set
      for (var entry in exerciseFeedbacks.entries) {
        if (_isValidFeedback(entry.value)) {
          feedbackExercises.add(entry.key);

          // Check for detailed feedback achievement
          if (entry.value['areas']?.isNotEmpty == true &&
              entry.value['comment']?.isNotEmpty == true) {
            hasDetailedFeedback = true;
            debugPrint('Detailed feedback provided for exercise: ${entry.key}');
          }
        }
      }

      // Save updated feedback exercises
      await doc.reference.set({
        'feedbackExercises': feedbackExercises.toList(),
      }, SetOptions(merge: true));

      debugPrint('Total unique exercises with feedback: ${feedbackExercises.length}');

      // Check feedback count achievements
      if (feedbackExercises.length >= 5) {
        debugPrint('Unlocking exercise_feedback_starter achievement');
        await _unlockAchievement('exercise_feedback_starter');
      }
      if (feedbackExercises.length >= 20) {
        debugPrint('Unlocking exercise_feedback_pro achievement');
        await _unlockAchievement('exercise_feedback_pro');
      }

      // Check detailed feedback achievement
      if (hasDetailedFeedback) {
        debugPrint('Unlocking detailed_feedback achievement');
        await _unlockAchievement('detailed_feedback');
      }

    } catch (e) {
      debugPrint('Error checking feedback achievements: $e');
    }
  }

  bool _isValidFeedback(Map<String, dynamic> feedback) {
    return (feedback['areas']?.isNotEmpty == true) || 
           (feedback['comment']?.isNotEmpty == true);
  }

  // Private methods for specific achievement checks
  Future<void> _checkWorkoutCompletionAchievements(
    List<Map<String, dynamic>> exercises,
    Map<String, List<bool>> completedSets,
  ) async {
    try {
      final completedExercises = exercises.where((exercise) {
        final exerciseId = exercise['exerciseId'];
        return completedSets[exerciseId]?.every((checked) => checked) ?? false;
      }).length;

      final completionRate = completedExercises / exercises.length;

      if (completionRate == 1.0) {
        await _unlockAchievement('perfect_workout');
      }

      // Check for workout_master achievement
      await _checkWorkoutStreak(completionRate);
    } catch (e) {
      debugPrint('Error checking workout completion achievements: $e');
    }
  }

  Future<void> _checkWorkoutTimeAchievements(Duration workoutDuration, bool isEarlyBird) async {
    try {
      // Check workout duration achievement
      if (workoutDuration.inMinutes >= 90) {
        debugPrint('Workout duration: ${workoutDuration.inMinutes} minutes - Unlocking duration master achievement');
        await _unlockAchievement('workout_duration_master');
      }

      // Check early bird achievement
      if (isEarlyBird) {
        final doc = await FirebaseFirestore.instance
            .collection('achievement_progress')
            .doc(userId)
            .get();

        final earlyWorkouts = doc.data()?['earlyWorkouts'] ?? 0;
        
        await doc.reference.set({
          'earlyWorkouts': earlyWorkouts + 1,
        }, SetOptions(merge: true));

        debugPrint('Early workouts completed: ${earlyWorkouts + 1}');

        if (earlyWorkouts + 1 >= 5) {
          await _unlockAchievement('early_bird');
        }
      }
    } catch (e) {
      debugPrint('Error checking workout time achievements: $e');
    }
  }

  // Helper methods
  Future<void> _unlockAchievement(String achievementId) async {
    if (!userProvider.hasAchievement(achievementId)) {
      await userProvider.unlockAchievement(achievementId);
    }
  }

  Future<void> _checkWorkoutStreak(double completionRate) async {
    if (completionRate < 0.8) return;

    final doc = await FirebaseFirestore.instance
        .collection('achievement_progress')
        .doc(userId)
        .get();

    final currentStreak = doc.data()?['workoutStreak'] ?? 0;
    if (currentStreak + 1 >= 5) {
      await _unlockAchievement('workout_master');
      // Reset streak after achieving
      await doc.reference.set({'workoutStreak': 0}, SetOptions(merge: true));
    } else {
      await doc.reference.set(
        {'workoutStreak': currentStreak + 1},
        SetOptions(merge: true),
      );
    }
  }

  Future<void> _checkWeightLossAchievements(double? weightLoss) async {
    if (weightLoss == null) return;

    try {
      // Get recent measurements to check time frames
      final measurements = await FirebaseFirestore.instance
          .collection('progress_logs')
          .doc(userId)
          .collection('all_progress_logs')
          .where('date', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 180))  // Check up to 180 days
          ))
          .orderBy('date')
          .get();

      if (measurements.docs.isEmpty) return;

      // Check each weight loss achievement
      for (final achievement in ClientAchievements.weightLoss) {
        if (!userProvider.hasAchievement(achievement.id)) {
          final requiredLoss = achievement.criteria['weightLoss'] as double;
          final timeFrame = achievement.criteria['timeFrameDays'] as int;
          
          // Only check if weight loss meets criteria
          if (weightLoss >= requiredLoss) {
            final startDate = (measurements.docs.first.data()['date'] as Timestamp).toDate();
            final daysInPeriod = DateTime.now().difference(startDate).inDays;

            // Check if loss was achieved within required time frame
            if (daysInPeriod <= timeFrame) {
              debugPrint('Unlocking achievement ${achievement.id}: $weightLoss kg lost in $daysInPeriod days');
              await _unlockAchievement(achievement.id);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking weight loss achievements: $e');
    }
  }

  Future<void> _checkBodyCompositionAchievements(
    double? bodyFatReduction,
    double? muscleGain,
  ) async {
    try {
      // Get recent measurements to check time frames
      final measurements = await FirebaseFirestore.instance
          .collection('progress_logs')
          .doc(userId)
          .collection('all_progress_logs')
          .where('date', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 120))  // Check up to 120 days (longest timeframe)
          ))
          .orderBy('date')
          .get();

      if (measurements.docs.isEmpty) return;

      for (final achievement in ClientAchievements.bodyComposition) {
        if (!userProvider.hasAchievement(achievement.id)) {
          final timeFrame = achievement.criteria['timeFrameDays'] as int;
          final startDate = (measurements.docs.first.data()['date'] as Timestamp).toDate();
          final daysInPeriod = DateTime.now().difference(startDate).inDays;

          // Only check if within time frame
          if (daysInPeriod <= timeFrame) {
            if (achievement.criteria.containsKey('bodyFatReduction') && 
                bodyFatReduction != null) {
              final requiredReduction = achievement.criteria['bodyFatReduction'] as double;
              if (bodyFatReduction >= requiredReduction) {
                debugPrint('Unlocking achievement ${achievement.id}: $bodyFatReduction% body fat reduced in $daysInPeriod days');
                await _unlockAchievement(achievement.id);
              }
            } else if (achievement.criteria.containsKey('muscleGain') && 
                       muscleGain != null) {
              final requiredGain = achievement.criteria['muscleGain'] as double;
              if (muscleGain >= requiredGain) {
                debugPrint('Unlocking achievement ${achievement.id}: $muscleGain kg muscle gained in $daysInPeriod days');
                await _unlockAchievement(achievement.id);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking body composition achievements: $e');
    }
  }

  Future<void> _checkTrackingAchievements(
    bool hasProgressPhotos,
    int daysSinceLastProgress,
  ) async {
    try {
      // Check progress photo achievement
      if (hasProgressPhotos) {
        await _unlockAchievement('first_progress_photo');
      }

      // Check measurement streak achievement
      if (daysSinceLastProgress <= 7) { // Within a week
        final doc = await FirebaseFirestore.instance
            .collection('achievement_progress')
            .doc(userId)
            .get();

        final currentWeeks = doc.data()?['measurementWeeks'] ?? 0;
        if (currentWeeks + 1 >= 4) { // 4 consecutive weeks
          await _unlockAchievement('measurement_streak');
          // Reset counter after achievement
          await doc.reference.set({'measurementWeeks': 0}, SetOptions(merge: true));
        } else {
          await doc.reference.set(
            {'measurementWeeks': currentWeeks + 1},
            SetOptions(merge: true),
          );
        }
      } else {
        // Reset streak if more than a week has passed
        await FirebaseFirestore.instance
            .collection('achievement_progress')
            .doc(userId)
            .set({'measurementWeeks': 0}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error checking tracking achievements: $e');
    }
  }

  Future<void> checkStrengthAchievements({
    required List<Map<String, dynamic>> exercises,
    required Map<String, List<bool>> completedSets,
    required Map<String, List<TextEditingController>> weightControllers,
  }) async {
    try {
      for (var exercise in exercises) {
        final exerciseId = exercise['exerciseId'];
        
        // Check if this exercise was completed
        if (completedSets[exerciseId]?.every((checked) => checked) ?? false) {
          // Get the maximum weight used in any set
          double maxWeight = 0;
          for (var i = 0; i < (exercise['sets'] as List).length; i++) {
            final weightText = weightControllers[exerciseId]?[i].text ?? '0';
            final weight = double.tryParse(weightText) ?? 0;
            if (weight > maxWeight) maxWeight = weight;
          }

          // Check strength achievements
          if (exercise['name'].toString().toLowerCase().contains('bench press')) {
            for (final achievement in ClientAchievements.strength) {
              if (!userProvider.hasAchievement(achievement.id) &&
                  achievement.criteria['exercise'] == 'bench_press') {
                final requiredWeight = achievement.criteria['weight'] as double;
                if (maxWeight >= requiredWeight) {
                  await _unlockAchievement(achievement.id);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking strength achievements: $e');
    }
  }

  Future<void> _checkExerciseVarietyAchievements(
    List<Map<String, dynamic>> exercises,
  ) async {
    try {
      // Get user's exercise history
      final doc = await FirebaseFirestore.instance
          .collection('achievement_progress')
          .doc(userId)
          .get();

      // Get or create set of unique exercises
      final uniqueExercises = Set<String>.from(
        doc.data()?['uniqueExercises'] ?? [],
      );

      // Add new exercises to the set
      for (var exercise in exercises) {
        uniqueExercises.add(exercise['name'] as String);
      }

      // Save updated unique exercises
      await doc.reference.set({
        'uniqueExercises': uniqueExercises.toList(),
      }, SetOptions(merge: true));

      // Check achievements
      for (final achievement in ClientAchievements.exerciseVariety) {
        if (!userProvider.hasAchievement(achievement.id)) {
          final requiredCount = achievement.criteria['uniqueExercises'] as int;
          if (uniqueExercises.length >= requiredCount) {
            await _unlockAchievement(achievement.id);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking exercise variety achievements: $e');
    }
  }

  Future<void> _checkWorkoutPlanAchievements(String planId, bool isCompleted) async {
    if (!isCompleted) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('achievement_progress')
          .doc(userId)
          .get();

      // Get or initialize completed plans set
      final completedPlans = Set<String>.from(
        doc.data()?['completedPlans'] ?? [],
      );

      // Add this plan if not already completed
      if (!completedPlans.contains(planId)) {
        completedPlans.add(planId);
        
        // Save updated completed plans
        await doc.reference.set({
          'completedPlans': completedPlans.toList(),
        }, SetOptions(merge: true));

        // Check achievements
        await _unlockAchievement('plan_completer');  // First plan completion

        if (completedPlans.length >= 3) {
          await _unlockAchievement('plan_master');  // Three plans completed
        }
      }
    } catch (e) {
      debugPrint('Error checking workout plan achievements: $e');
    }
  }

  Future<void> _checkSocialAchievements(Map<String, dynamic> profileData) async {
    try {
      // Check if profile is complete
      final requiredFields = ['fullName', 'username', 'email', 'phoneNumber', 'profileImageUrl'];
      final isProfileComplete = requiredFields.every((field) => 
        profileData[field] != null && profileData[field].toString().isNotEmpty);

      if (isProfileComplete) {
        await _unlockAchievement('profile_complete');
      }
    } catch (e) {
      debugPrint('Error checking social achievements: $e');
    }
  }

  Future<void> checkWorkoutStreakAchievements() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('achievement_progress')
          .doc(userId)
          .get();

      // Get total workouts completed
      final totalWorkouts = doc.data()?['totalWorkoutsCompleted'] ?? 0;
      
      // Increment total workouts
      await doc.reference.set({
        'totalWorkoutsCompleted': totalWorkouts + 1,
      }, SetOptions(merge: true));

      // Check streak achievements
      if (totalWorkouts + 1 >= 10) {
        await _unlockAchievement('workout_streak_10');
      }
      if (totalWorkouts + 1 >= 30) {
        await _unlockAchievement('workout_streak_30');
      }

      // Check for perfect month
      await _checkPerfectMonth();
    } catch (e) {
      debugPrint('Error checking workout streak achievements: $e');
    }
  }

  Future<void> _checkPerfectMonth() async {
    try {
      // Get the current month's scheduled and completed workouts
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Get scheduled workouts
      final scheduledWorkouts = await FirebaseFirestore.instance
          .collection('workouts')
          .doc('clients')
          .collection(userId)
          .where('scheduledDate', isGreaterThanOrEqualTo: startOfMonth)
          .where('scheduledDate', isLessThanOrEqualTo: endOfMonth)
          .get();

      // Get completed workouts
      final completedWorkouts = await FirebaseFirestore.instance
          .collection('workout_history')
          .doc('clients')
          .collection(userId)
          .where('completedAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('completedAt', isLessThanOrEqualTo: endOfMonth)
          .get();

      // Check if all scheduled workouts are completed
      if (scheduledWorkouts.docs.isNotEmpty &&
          scheduledWorkouts.docs.length == completedWorkouts.docs.length) {
        await _unlockAchievement('perfect_month');
      }
    } catch (e) {
      debugPrint('Error checking perfect month achievement: $e');
    }
  }

  Future<void> checkPersonalRecordAchievements(
    Map<String, dynamic> currentWorkout,
    Map<String, dynamic>? previousBest,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('achievement_progress')
          .doc(userId)
          .get();

      // Track if any PR was set
      bool prSet = false;
      final prCount = doc.data()?['monthlyPRCount'] ?? 0;
      final lastPRMonth = doc.data()?['lastPRMonth'];

      // Compare current performance with previous best
      for (var exercise in currentWorkout['exercises'] as List) {
        final exerciseId = exercise['exerciseId'];
        final currentMax = _getMaxWeight(exercise);
        final previousMax = _getMaxWeight(previousBest?['exercises']
            ?.firstWhere((e) => e['exerciseId'] == exerciseId, orElse: () => null));

        if (previousMax != null && currentMax > previousMax) {
          prSet = true;
          break;
        }
      }

      if (prSet) {
        // First PR achievement
        await _unlockAchievement('first_pr');

        // Check monthly PR count
        final currentMonth = DateTime.now().month;
        if (lastPRMonth == currentMonth) {
          final newPRCount = prCount + 1;
          if (newPRCount >= 5) {
            await _unlockAchievement('pr_streak');
          }
          await doc.reference.set({
            'monthlyPRCount': newPRCount,
          }, SetOptions(merge: true));
        } else {
          // Reset for new month
          await doc.reference.set({
            'monthlyPRCount': 1,
            'lastPRMonth': currentMonth,
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('Error checking personal record achievements: $e');
    }
  }

  double _getMaxWeight(Map<String, dynamic>? exercise) {
    if (exercise == null) return 0;
    
    double maxWeight = 0;
    for (var set in exercise['sets'] as List) {
      final weight = double.tryParse(set['actual']['weight'] ?? '0') ?? 0;
      if (weight > maxWeight) maxWeight = weight;
    }
    return maxWeight;
  }

  // Add more private methods for other achievement checks...
} 