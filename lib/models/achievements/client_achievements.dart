import 'package:flutter/material.dart';

enum AchievementDifficulty {
  easy,
  medium,
  hard,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementDifficulty difficulty;
  final String category;
  final Map<String, dynamic> criteria;
  final String usage;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.difficulty,
    required this.category,
    required this.criteria,
    required this.usage,
  });
}

class ClientAchievements {
  // Weight Loss Achievements
  static final List<Achievement> weightLoss = [
    const Achievement(
      id: 'weight_loss_5kg',
      title: 'Getting Started',
      description: 'Lost 5kg',
      icon: Icons.monitor_weight,
      difficulty: AchievementDifficulty.easy,
      category: 'Weight Loss',
      criteria: {'weightLoss': 5.0, 'timeFrameDays': 60},
      usage: 'Checked in client_log_progress_page.dart via checkProgressAchievements',
    ),
    const Achievement(
      id: 'weight_loss_10kg',
      title: 'Committed to Change',
      description: 'Lost 10kg',
      icon: Icons.monitor_weight,
      difficulty: AchievementDifficulty.medium,
      category: 'Weight Loss',
      criteria: {'weightLoss': 10.0, 'timeFrameDays': 90},
      usage: 'Checked in client_log_progress_page.dart via checkProgressAchievements',
    ),
    const Achievement(
      id: 'weight_loss_20kg',
      title: 'Major Transformation',
      description: 'Lost 20kg',
      icon: Icons.monitor_weight,
      difficulty: AchievementDifficulty.hard,
      category: 'Weight Loss',
      criteria: {'weightLoss': 20.0, 'timeFrameDays': 180},
      usage: 'Checked in client_log_progress_page.dart via checkProgressAchievements',
    ),
  ];

  // Strength Milestones
  static final List<Achievement> strength = [
    const Achievement(
      id: 'bench_40kg',
      title: 'Novice Presser',
      description: 'Bench Press 40kg',
      icon: Icons.fitness_center,
      difficulty: AchievementDifficulty.easy,
      category: 'Strength',
      criteria: {'exercise': 'bench_press', 'weight': 40.0},
      usage: 'Checked in workout_in_progress_page.dart via checkStrengthAchievements',
    ),
    const Achievement(
      id: 'bench_60kg',
      title: 'Intermediate Presser',
      description: 'Bench Press 60kg',
      icon: Icons.fitness_center,
      difficulty: AchievementDifficulty.medium,
      category: 'Strength',
      criteria: {'exercise': 'bench_press', 'weight': 60.0},
      usage: 'Checked in WorkoutInProgressPage when completing bench press exercise with weight >= 60kg',
    ),
    const Achievement(
      id: 'bench_80kg',
      title: 'Advanced Presser',
      description: 'Bench Press 80kg',
      icon: Icons.fitness_center,
      difficulty: AchievementDifficulty.hard,
      category: 'Strength',
      criteria: {'exercise': 'bench_press', 'weight': 80.0},
      usage: 'Checked in WorkoutInProgressPage when completing bench press exercise with weight >= 80kg',
    ),
  ];

  // Body Composition Achievements
  static final List<Achievement> bodyComposition = [
    const Achievement(
      id: 'muscle_gain_2kg',
      title: 'Muscle Builder Beginner',
      description: 'Gained 2kg of muscle mass',
      icon: Icons.accessibility_new,
      difficulty: AchievementDifficulty.easy,
      category: 'Body Composition',
      criteria: {'muscleGain': 2.0, 'timeFrameDays': 60},
      usage: 'Checked in client_log_progress_page.dart via checkProgressAchievements',
    ),
    const Achievement(
      id: 'muscle_gain_5kg',
      title: 'Muscle Builder Pro',
      description: 'Gained 5kg of muscle mass',
      icon: Icons.accessibility_new,
      difficulty: AchievementDifficulty.medium,
      category: 'Body Composition',
      criteria: {'muscleGain': 5.0, 'timeFrameDays': 120},
      usage: 'Checked in client_log_progress_page.dart via checkProgressAchievements',
    ),
    const Achievement(
      id: 'body_fat_reduction_5',
      title: 'Fat Loss Champion',
      description: 'Reduced body fat by 5%',
      icon: Icons.speed,
      difficulty: AchievementDifficulty.hard,
      category: 'Body Composition',
      criteria: {'bodyFatReduction': 5.0, 'timeFrameDays': 90},
      usage: 'Checked in client_log_progress_page.dart via checkProgressAchievements',
    ),
  ];

  // Consistency Achievements
  static final List<Achievement> consistency = [
    const Achievement(
      id: 'workout_streak_10',
      title: 'Consistency Starter',
      description: 'Completed 10 workouts',
      icon: Icons.timer,
      difficulty: AchievementDifficulty.easy,
      category: 'Consistency',
      criteria: {'workouts': 10},
      usage: 'Checked in WorkoutInProgressPage after workout completion',
    ),
    const Achievement(
      id: 'workout_streak_30',
      title: 'Workout Warrior',
      description: 'Completed 30 workouts',
      icon: Icons.timer,
      difficulty: AchievementDifficulty.medium,
      category: 'Consistency',
      criteria: {'workouts': 30},
      usage: 'Checked in WorkoutInProgressPage after workout completion',
    ),
    const Achievement(
      id: 'perfect_month',
      title: 'Perfect Month',
      description: 'Completed all scheduled workouts in a month',
      icon: Icons.calendar_today,
      difficulty: AchievementDifficulty.hard,
      category: 'Consistency',
      criteria: {'perfectMonth': true},
      usage: 'Checked in WorkoutInProgressPage after completing all workouts in a month',
    ),
  ];

  // Progress Tracking Achievements
  static final List<Achievement> tracking = [
    const Achievement(
      id: 'first_progress_photo',
      title: 'Picture Perfect',
      description: 'Posted first progress photo',
      icon: Icons.photo_camera,
      difficulty: AchievementDifficulty.easy,
      category: 'Tracking',
      criteria: {'progressPhotos': 1},
      usage: 'Checked in client_log_progress_page.dart via checkProgressAchievements',
    ),
    const Achievement(
      id: 'measurement_streak',
      title: 'Measurement Master',
      description: 'Logged measurements for 4 consecutive weeks',
      icon: Icons.straighten,
      difficulty: AchievementDifficulty.medium,
      category: 'Tracking',
      criteria: {'measurementWeeks': 4},
      usage: 'Checked in client_log_progress_page.dart via checkProgressAchievements',
    ),
  ];

  // Workout Completion Achievements
  static final List<Achievement> workoutCompletion = [
    const Achievement(
      id: 'perfect_workout',
      title: 'Perfectionist',
      description: 'Complete all exercises in a workout',
      icon: Icons.done_all,
      difficulty: AchievementDifficulty.medium,
      category: 'Workout',
      criteria: {'completionRate': 1.0},
      usage: 'Checked in WorkoutInProgressPage after completing a workout',
    ),
    const Achievement(
      id: 'workout_master',
      title: 'Workout Master',
      description: 'Complete 80% or more of exercises in 5 consecutive workouts',
      icon: Icons.fitness_center,
      difficulty: AchievementDifficulty.hard,
      category: 'Workout',
      criteria: {'completionRate': 0.8, 'streak': 5},
      usage: 'Checked in WorkoutInProgressPage after completing 80% of workouts',
    ),
  ];

  // Exercise Variety Achievements
  static final List<Achievement> exerciseVariety = [
    const Achievement(
      id: 'exercise_explorer',
      title: 'Exercise Explorer',
      description: 'Try 10 different exercises',
      icon: Icons.explore,
      difficulty: AchievementDifficulty.easy,
      category: 'Exercise Variety',
      criteria: {'uniqueExercises': 10},
      usage: 'Checked in workout_in_progress_page.dart via checkWorkoutAchievements',
    ),
    const Achievement(
      id: 'exercise_master',
      title: 'Exercise Master',
      description: 'Complete 30 different exercises',
      icon: Icons.stars,
      difficulty: AchievementDifficulty.medium,
      category: 'Exercise Variety',
      criteria: {'uniqueExercises': 30},
      usage: 'Checked in WorkoutInProgressPage via _checkExerciseVarietyAchievements',
    ),
  ];

  // Workout Time Achievements
  static final List<Achievement> workoutTime = [
    const Achievement(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Complete 5 workouts before 8 AM',
      icon: Icons.wb_sunny,
      difficulty: AchievementDifficulty.medium,
      category: 'Workout Time',
      criteria: {'earlyWorkouts': 5, 'beforeHour': 8},
      usage: 'Checked in workout_in_progress_page.dart via checkWorkoutTimeAchievements',
    ),
    const Achievement(
      id: 'workout_duration_master',
      title: 'Endurance Champion',
      description: 'Complete a workout lasting over 90 minutes',
      icon: Icons.timer,
      difficulty: AchievementDifficulty.hard,
      category: 'Workout Time',
      criteria: {'duration': 90},
      usage: 'Checked in workout_in_progress_page.dart via checkWorkoutTimeAchievements',
    ),
  ];

  // Personal Records Achievements
  static final List<Achievement> personalRecords = [
    const Achievement(
      id: 'first_pr',
      title: 'Record Breaker',
      description: 'Set your first personal record',
      icon: Icons.emoji_events,
      difficulty: AchievementDifficulty.easy,
      category: 'Personal Records',
      criteria: {'prCount': 1},
      usage: 'Not implemented yet',
    ),
    const Achievement(
      id: 'pr_streak',
      title: 'Constant Improvement',
      description: 'Set 5 personal records in a month',
      icon: Icons.trending_up,
      difficulty: AchievementDifficulty.hard,
      category: 'Personal Records',
      criteria: {'prCount': 5, 'timeFrameDays': 30},
      usage: 'Not implemented yet',
    ),
  ];

  // Workout Plans Achievements
  static final List<Achievement> workoutPlans = [
    const Achievement(
      id: 'plan_completer',
      title: 'Plan Completer',
      description: 'Complete an entire workout plan',
      icon: Icons.assignment_turned_in,
      difficulty: AchievementDifficulty.medium,
      category: 'Workout Plans',
      criteria: {'completePlan': true},
      usage: 'Checked in WorkoutPlansPage after completing an entire workout plan',
    ),
    const Achievement(
      id: 'plan_master',
      title: 'Plan Master',
      description: 'Complete 3 different workout plans',
      icon: Icons.auto_awesome,
      difficulty: AchievementDifficulty.hard,
      category: 'Workout Plans',
      criteria: {'completePlans': 3},
      usage: 'Checked in WorkoutPlansPage after completing 3 different workout plans',
    ),
  ];

  // Social Achievements
  static final List<Achievement> social = [
    const Achievement(
      id: 'profile_complete',
      title: 'Profile Pro',
      description: 'Complete your profile with all information',
      icon: Icons.person_outline,
      difficulty: AchievementDifficulty.easy,
      category: 'Social',
      criteria: {'profileComplete': true},
      usage: 'Checked in data_fetch_service.dart via checkProfileAchievements',
    ),
    const Achievement(
      id: 'feedback_provider',
      title: 'Feedback Champion',
      description: 'Provide feedback for 10 workouts',
      icon: Icons.rate_review,
      difficulty: AchievementDifficulty.medium,
      category: 'Social',
      criteria: {'feedbackCount': 10},
      usage: 'Checked in workout_in_progress_page.dart via checkFeedbackAchievements',
    ),
    const Achievement(
      id: 'exercise_feedback_starter',
      title: 'Feedback Beginner',
      description: 'Provide feedback for 5 different exercises',
      icon: Icons.rate_review,
      difficulty: AchievementDifficulty.easy,
      category: 'Social',
      criteria: {'exerciseFeedbackCount': 5},
      usage: 'Checked in workout_in_progress_page.dart via checkFeedbackAchievements',
    ),
    const Achievement(
      id: 'exercise_feedback_pro',
      title: 'Feedback Champion',
      description: 'Provide feedback for 20 different exercises',
      icon: Icons.rate_review,
      difficulty: AchievementDifficulty.medium,
      category: 'Social',
      criteria: {'exerciseFeedbackCount': 20},
      usage: 'Checked in workout_in_progress_page.dart via checkFeedbackAchievements',
    ),
    const Achievement(
      id: 'detailed_feedback',
      title: 'Detailed Reviewer',
      description: 'Provide both comments and category selections in feedback',
      icon: Icons.format_list_bulleted,
      difficulty: AchievementDifficulty.easy,
      category: 'Social',
      criteria: {'hasDetailedFeedback': true},
      usage: 'Checked in workout_in_progress_page.dart via checkFeedbackAchievements',
    ),
  ];

  // Get all achievements
  static List<Achievement> getAllAchievements() {
    return [
      ...weightLoss,
      ...strength,
      ...bodyComposition,
      ...consistency,
      ...tracking,
      ...workoutCompletion,
      ...exerciseVariety,
      ...workoutTime,
      ...personalRecords,
      ...workoutPlans,
      ...social,
    ];
  }

  // Get achievements by difficulty
  static List<Achievement> getByDifficulty(AchievementDifficulty difficulty) {
    return getAllAchievements()
        .where((achievement) => achievement.difficulty == difficulty)
        .toList();
  }

  // Get achievements by category
  static List<Achievement> getByCategory(String category) {
    return getAllAchievements()
        .where((achievement) => achievement.category == category)
        .toList();
  }
} 