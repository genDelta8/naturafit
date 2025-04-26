import 'package:naturafit/models/achievements/client_achievements.dart';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/widgets/custom_fitness_level_slider.dart';
import 'package:naturafit/widgets/custom_loading_view.dart';
import 'package:naturafit/services/achievement_service.dart';
import 'package:naturafit/views/all_shared_settings/exercise_feedback_sheet.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/widgets/workout_countdown_view.dart';
import 'package:naturafit/services/notification_service.dart';
import 'package:naturafit/widgets/custom_video_player.dart';
import 'package:naturafit/widgets/image_gallery_screen.dart';

// Add this before the WorkoutInProgressPage class
class PhaseWithExercises {
  final String name;
  final String id;
  final List<Map<String, dynamic>> exercises;

  PhaseWithExercises({
    required this.name,
    required this.id,
    required this.exercises,
  });
}

class WorkoutInProgressPage extends StatefulWidget {
  final Map<String, dynamic> workout;
  final int selectedDay;
  final bool isEnteredByTrainer;

  const WorkoutInProgressPage({
    super.key,
    required this.workout,
    required this.selectedDay,
    this.isEnteredByTrainer = false,
  });

  @override
  State<WorkoutInProgressPage> createState() => _WorkoutInProgressPageState();
}

class _WorkoutInProgressPageState extends State<WorkoutInProgressPage> {
  int _currentExerciseIndex = 0;
  int _countDown = 3;
  bool _workoutStarted = false;
  Duration _elapsedTime = Duration.zero;
  Duration _exerciseTime = Duration.zero;
  Timer? _workoutTimer;
  Timer? _exerciseTimer;
  Timer? _countDownTimer;
  Map<String, List<bool>> completedSets = {};
  Map<String, bool> savedExercises = {};
  Map<String, Duration> exerciseTimers = {};
  Map<String, List<Map<String, dynamic>>> actualSetValues = {};
  Map<String, List<TextEditingController>> repsControllers = {};
  Map<String, List<TextEditingController>> weightControllers = {};
  Map<String, List<TextEditingController>> restControllers = {};
  bool _isSubmitting = false;

  String _selectedDifficulty = 'Level 3'; // Default difficulty level
  final _notesController = TextEditingController();

  // Add this to your existing state variables
  Map<String, TextEditingController> exerciseFeedbackControllers = {};
  Map<String, Map<String, dynamic>> exerciseFeedbacks =
      {}; // To store feedbacks with both areas and comments

  // First, let's create a helper class to organize exercises by phase
  List<PhaseWithExercises> get exercisesByPhase {
    final workoutDay = widget.workout['workoutDays'][widget.selectedDay];
    final phases = workoutDay['phases'] as List<dynamic>;

    return phases.map((phase) {
      return PhaseWithExercises(
        name: phase['name'] ?? 'Unnamed Phase',
        id: phase['id'] ?? '',
        exercises: (phase['exercises'] as List).map((e) {
          final exerciseData = Map<String, dynamic>.from(e);
          return {
            ...exerciseData,
            'phaseName': phase['name'],
            'phaseId': phase['id'],
            'isBookmarked': exerciseData['isBookmarked'] ??
                false, // Ensure this field exists
          };
        }).toList(),
      );
    }).toList();
  }

  // First, let's add a helper method to generate consistent exercise IDs
  String _generateExerciseId(
      Map<String, dynamic> exercise, String phaseId, int index) {
    return exercise['exerciseId'] ?? 'exercise_${phaseId}_$index';
  }

  // Update the exercises getter to include phase information
  List<Map<String, dynamic>> get exercises {
    return exercisesByPhase
        .expand((phase) => phase.exercises.map((exercise) {
              final index = phase.exercises.indexOf(exercise);
              final exerciseId = _generateExerciseId(exercise, phase.id, index);
              return {
                ...exercise,
                'exerciseId': exerciseId,
                'phaseName': phase.name,
                'phaseId': phase.id,
              };
            }))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _startCountDown();

    debugPrint('Raw workout data: ${widget.workout}');

    // Initialize bookmark states from workout data
    for (var phase in exercisesByPhase) {
      for (var exercise in phase.exercises) {
        final exerciseId = _generateExerciseId(
            exercise, phase.id, phase.exercises.indexOf(exercise));
        // Set the initial bookmark state from the workout data
        savedExercises[exerciseId] = exercise['isBookmarked'] ?? false;
        debugPrint(
            'Exercise ID: $exerciseId, Bookmark State: ${savedExercises[exerciseId]}');
        debugPrint('Exercise bookmarked: ${exercise['isBookmarked'] ?? false}');
      }
    }
  }

  void _startCountDown() {
    _countDownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countDown > 0) {
          _countDown--;
        } else {
          timer.cancel();
          _startWorkout();
        }
      });
    });
  }

  void _startWorkout() {
    setState(() {
      _workoutStarted = true;
    });
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime += const Duration(seconds: 1);
      });
    });
    _startExerciseTimer();
  }

  void _startExerciseTimer() {
    _exerciseTimer?.cancel();
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _exerciseTime += const Duration(seconds: 1);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _exerciseTimer?.cancel();
    _countDownTimer?.cancel();

    // Dispose all controllers
    for (var controllers in repsControllers.values) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    for (var controllers in weightControllers.values) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    for (var controllers in restControllers.values) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }

    // Add this to your dispose method
    for (var controller in exerciseFeedbackControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  bool _isExerciseCompleted(Map<String, dynamic> exercise, int index) {
    final exerciseId = exercise['exerciseId'] ?? 'exercise_$index';
    final sets = completedSets[exerciseId];
    return sets != null && sets.every((checked) => checked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final generateSize = screenWidth * 0.175;
    final iconSize = screenWidth * 0.1;
    final generateLargerPadding = screenWidth * 0.085;
    final generateSmallerPadding = screenWidth * 0.042;
    final fadeRadius = screenWidth * 0.075;
    final buttonRadius = screenWidth * 0.035;
    final baseColor = myRed20;
    final myBackground = myRed60;
    final theme = Theme.of(context);
    final userData = Provider.of<UserProvider>(context).userData;
    final weightUnit = userData?['weightUnit'];
    final unitPrefs = Provider.of<UnitPreferences>(context, listen: false);

    if (!_workoutStarted) {
      return WorkoutCountdownView(countDown: _countDown);
    }

    final currentExercise = exercises[_currentExerciseIndex];

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                    color: theme.brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                    width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.chevron_left,
                    color: theme.brightness == Brightness.light
                        ? Colors.black
                        : Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            centerTitle: true,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                //color: myBlue60,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDuration(_elapsedTime),
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _finishWorkout(userData, unitPrefs),
                icon: Icon(Icons.stop_circle_outlined,
                    color: theme.brightness == Brightness.light
                        ? Colors.black
                        : Colors.white),
                label: Text(
                  l10n.finish,
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
            ],
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Exercise Progress Stepper
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: exercises.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exercise = entry.value;
                    final isVisited = index <= _currentExerciseIndex;
                    final isCurrent = index == _currentExerciseIndex;
                    final isCompleted =
                        isVisited && _isExerciseCompleted(exercise, index);

                    final phaseColor =
                        _getPhaseColor(exercise['phaseName'] ?? '');

                    return Column(
                      children: [
                        Row(
                          children: [
                            if (index > 0)
                              Container(
                                width: 20,
                                height: 1,
                                color: myGrey60,
                              ),
                            GestureDetector(
                              onTap: () {
                                if (index != _currentExerciseIndex) {
                                  setState(() {
                                    // Save current exercise time
                                    final currentId =
                                        exercises[_currentExerciseIndex]
                                                ['exerciseId'] ??
                                            'exercise_$_currentExerciseIndex';
                                    exerciseTimers[currentId] = _exerciseTime;

                                    // Update current exercise
                                    _currentExerciseIndex = index;

                                    // Restore selected exercise time
                                    final selectedId = exercise['exerciseId'] ??
                                        'exercise_$index';
                                    _exerciseTime =
                                        exerciseTimers[selectedId] ??
                                            Duration.zero;
                                  });
                                }
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? myBlue60
                                      : (isCompleted
                                          ? myGreen50
                                          : (isVisited ? myRed50 : myGrey80)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isCurrent
                                      ? Icons.fitness_center
                                      : (isCompleted
                                          ? Icons.check
                                          : (isVisited
                                              ? Icons.close
                                              : Icons.circle)),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (index > 0)
                              Container(
                                width: 20,
                                height: 1,
                                color: exercises[index - 1]['phaseName'] ==
                                        exercise['phaseName']
                                    ? phaseColor
                                    : Colors.transparent,
                              ),
                            Container(
                              width: 40,
                              height: 10,
                              decoration: BoxDecoration(
                                color: phaseColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              // Add exercise navigation here
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentExerciseIndex > 0)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentExerciseIndex--;
                          });
                          // Save current exercise time before switching
                          final currentId = exercises[_currentExerciseIndex + 1]
                                  ['exerciseId'] ??
                              'exercise_${_currentExerciseIndex + 1}';
                          exerciseTimers[currentId] = _exerciseTime;

                          // Restore previous exercise time
                          final prevId = exercises[_currentExerciseIndex]
                                  ['exerciseId'] ??
                              'exercise_$_currentExerciseIndex';
                          _exerciseTime =
                              exerciseTimers[prevId] ?? Duration.zero;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: theme.brightness == Brightness.light
                                    ? myGrey80
                                    : Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chevron_left,
                                color: theme.brightness == Brightness.light
                                    ? myGrey80
                                    : Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Back',
                                style: GoogleFonts.plusJakartaSans(
                                  color: theme.brightness == Brightness.light
                                      ? myGrey80
                                      : Colors.grey[400],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (_currentExerciseIndex < exercises.length - 1)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentExerciseIndex++;
                          });
                          // Save current exercise time before switching
                          final currentId = exercises[_currentExerciseIndex - 1]
                                  ['exerciseId'] ??
                              'exercise_${_currentExerciseIndex - 1}';
                          exerciseTimers[currentId] = _exerciseTime;

                          // Restore next exercise time
                          final nextId = exercises[_currentExerciseIndex]
                                  ['exerciseId'] ??
                              'exercise_$_currentExerciseIndex';
                          _exerciseTime =
                              exerciseTimers[nextId] ?? Duration.zero;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: theme.brightness == Brightness.light
                                    ? myGrey80
                                    : Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Next',
                                style: GoogleFonts.plusJakartaSans(
                                  color: theme.brightness == Brightness.light
                                      ? myGrey80
                                      : Colors.grey[400],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                color: theme.brightness == Brightness.light
                                    ? myGrey80
                                    : Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Current Exercise Details
              Expanded(
                child: ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thumbColor: WidgetStateProperty.all(
                        theme.brightness == Brightness.light
                            ? myGrey60
                            : Colors.grey[400]),
                    trackColor: WidgetStateProperty.all(
                        theme.brightness == Brightness.light
                            ? myGrey20
                            : myGrey70),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Exercise Card
                          Container(
                            //margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              //color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              /*
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                              */
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentExercise['name'] ?? '',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 24,
                                            color: theme.brightness ==
                                                    Brightness.light
                                                ? Colors.black
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          //margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: _getPhaseColor(
                                                currentExercise['phaseName'] ??
                                                    ''),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                currentExercise['phaseName'] ??
                                                    'Unnamed Phase',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                _getPhaseIcon(currentExercise[
                                                        'phaseName'] ??
                                                    ''),
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (currentExercise['equipment']
                                                ?.isNotEmpty ==
                                            true) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Equipment: ${currentExercise['equipment']}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              color: theme.brightness ==
                                                      Brightness.light
                                                  ? myGrey60
                                                  : Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDuration(_exerciseTime),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              final exerciseId = currentExercise[
                                                      'exerciseId'] ??
                                                  'exercise_$_currentExerciseIndex';
                                              savedExercises[exerciseId] =
                                                  !(savedExercises[
                                                          exerciseId] ??
                                                      false);
                                            });
                                          },
                                          icon: Icon(
                                            savedExercises[currentExercise[
                                                            'exerciseId'] ??
                                                        'exercise_$_currentExerciseIndex'] ??
                                                    false
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            color: savedExercises[currentExercise[
                                                            'exerciseId'] ??
                                                        'exercise_$_currentExerciseIndex'] ??
                                                    false
                                                ? myBlue60
                                                : theme.brightness ==
                                                        Brightness.light
                                                    ? myGrey60
                                                    : Colors.grey[400],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.rate_review_outlined,
                                            color: _hasValidFeedback(
                                                    currentExercise[
                                                            'exerciseId'] ??
                                                        'exercise_$_currentExerciseIndex')
                                                ? myBlue60
                                                : theme.brightness ==
                                                        Brightness.light
                                                    ? myGrey60
                                                    : Colors.grey[400],
                                            size: 24,
                                          ),
                                          onPressed: () => _showFeedbackSheet(
                                            currentExercise['exerciseId'] ??
                                                'exercise_$_currentExerciseIndex',
                                            currentExercise['name'] as String,
                                          ),
                                        ),
                                        if (currentExercise['videoUrl']?.isNotEmpty ?? false)
                                          IconButton(
                                            onPressed: () => _showFullScreenVideo(context, currentExercise['videoUrl']),
                                            icon: const Icon(Icons.play_circle_outline),
                                            color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                        if (currentExercise['imageUrls']?.isNotEmpty ?? false)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: GestureDetector(
                                                onTap: () => _showFullScreenImages(
                                                  context,
                                                  List<String>.from(currentExercise['imageUrls']),
                                                  0,
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.photo_library_outlined,
                                                      size: 16,
                                                      color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${(currentExercise['imageUrls'] as List?)?.length ?? 0}',
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Sets Table
                                Container(
                                  decoration: BoxDecoration(
                                    //color: myGrey10,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 30),
                                            Expanded(
                                              child: Text(
                                                'Reps',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color: theme.brightness ==
                                                          Brightness.light
                                                      ? myGrey80
                                                      : Colors.grey[400],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                weightUnit == 'kg'
                                                    ? 'Weight (kg)'
                                                    : 'Weight (lb)',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontSize: 14,
                                                  color: theme.brightness ==
                                                          Brightness.light
                                                      ? myGrey80
                                                      : Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                'Rest',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color: theme.brightness ==
                                                          Brightness.light
                                                      ? myGrey80
                                                      : Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 40),
                                          ],
                                        ),
                                      ),
                                      ...List.generate(
                                        (currentExercise['sets'] as List)
                                            .length,
                                        (setIndex) => _buildSetRow(
                                            setIndex + 1,
                                            currentExercise,
                                            weightUnit,
                                            unitPrefs),
                                      ),
                                      const SizedBox(height: 32),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Notes section moved outside
                          if (currentExercise['notes']?.isNotEmpty == true) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notes',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentExercise['notes'],
                                    style: GoogleFonts.plusJakartaSans(
                                      color: myGrey60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isSubmitting) const CustomLoadingView(),
      ],
    );
  }

  // Get phase color based on phase name
  Color _getPhaseColor(String phaseName) {
    switch (phaseName.toLowerCase()) {
      case 'warm up phase':
        return myYellow40;
      case 'main workout phase':
        return myTeal30;
      case 'cool down phase':
        return myBlue30;
      default:
        return myGrey40;
    }
  }

  IconData _getPhaseIcon(String phaseName) {
    switch (phaseName.toLowerCase()) {
      case 'warm up phase':
        return Icons.whatshot_outlined;
      case 'main workout phase':
        return Icons.fitness_center_outlined;
      case 'cool down phase':
        return Icons.ac_unit_outlined;
      default:
        return Icons.fitness_center_outlined;
    }
  }

  Map<String, dynamic> _convertSetWeights(
      Map<String, dynamic> set, UnitPreferences unitPrefs) {
    if (set['weight'] != null && set['weight'].isNotEmpty) {
      // Convert from lbs to kg if needed
      double weightKg = double.tryParse(set['weight']) ?? 0;
      double weightLbs = unitPrefs.kgToLbs(weightKg);
      return {
        ...set,
        'weight': weightLbs.toStringAsFixed(0),
      };
    }
    return set;
  }

  // Update _buildSetRow to use the helper method
  Widget _buildSetRow(int setNumber, Map<String, dynamic> exercise,
      String weightUnit, UnitPreferences unitPrefs) {
    final theme = Theme.of(context);
    final exerciseId = _generateExerciseId(
        exercise,
        exercise['phaseId'],
        exercisesByPhase
            .firstWhere((phase) => phase.id == exercise['phaseId'])
            .exercises
            .indexOf(exercise));
    final sets = exercise['sets'] as List<dynamic>;

    final convertedSets = weightUnit == 'lbs'
        ? sets.map((set) {
            return _convertSetWeights(
                Map<String, dynamic>.from(set), unitPrefs);
          }).toList()
        : sets.map((set) {
            return Map<String, dynamic>.from(set);
          }).toList();

    // Initialize completedSets if not already done
    if (completedSets[exerciseId] == null) {
      completedSets[exerciseId] =
          List.generate(convertedSets.length, (index) => false);
    }

    // Initialize controllers if not already done
    _initializeControllers(exercise, exerciseId, convertedSets.length);

    final set = convertedSets[setNumber - 1];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: completedSets[exerciseId]![setNumber - 1]
                ? myBlue30
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: completedSets[exerciseId]![setNumber - 1]
                  ? myBlue60
                  : theme.brightness == Brightness.light
                      ? Colors.white
                      : myGrey80,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: completedSets[exerciseId]![setNumber - 1]
                      ? myBlue60
                      : theme.brightness == Brightness.light
                          ? myGrey20
                          : myGrey70),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '$setNumber',
                    style: GoogleFonts.plusJakartaSans(
                      color: completedSets[exerciseId]![setNumber - 1]
                          ? Colors.white
                          : theme.brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (completedSets[exerciseId]![setNumber - 1]) ...[
                  Expanded(
                    child: _buildSetTextField(
                      exercise,
                      exerciseId,
                      setNumber - 1,
                      'reps',
                      repsControllers,
                      set['reps']?.toString() ?? '',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSetTextField(
                      exercise,
                      exerciseId,
                      setNumber - 1,
                      'weight',
                      weightControllers,
                      set['weight']?.toString() ?? '',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSetTextField(
                      exercise,
                      exerciseId,
                      setNumber - 1,
                      'rest',
                      restControllers,
                      set['rest']?.toString() ?? '',
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      set['reps']?.toString() ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.brightness == Brightness.light
                            ? myGrey80
                            : Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      set['weight']?.toString() ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.brightness == Brightness.light
                            ? myGrey80
                            : Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      set['rest']?.toString() ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.brightness == Brightness.light
                            ? myGrey80
                            : Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  width: 40,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        completedSets[exerciseId]![setNumber - 1] =
                            !completedSets[exerciseId]![setNumber - 1];
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: completedSets[exerciseId]![setNumber - 1]
                            ? Colors.white
                            : Colors.transparent,
                        border: Border.all(
                          color: completedSets[exerciseId]![setNumber - 1]
                              ? Colors.white
                              : myGrey60,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: completedSets[exerciseId]![setNumber - 1]
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: myBlue60,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (setNumber == (exercise['sets'] as List).length)
          Padding(
            padding: const EdgeInsets.only(top: 0, right: 16, bottom: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  final exerciseId = exercise['exerciseId'] ??
                      'exercise_$_currentExerciseIndex';
                  setState(() {
                    final allChecked = completedSets[exerciseId]
                            ?.every((checked) => checked) ??
                        false;
                    final sets = exercise['sets'] as List<dynamic>;
                    completedSets[exerciseId] = List.generate(
                      sets.length,
                      (_) => !allChecked,
                    );
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: completedSets[exercise['exerciseId'] ??
                                    'exercise_$_currentExerciseIndex']
                                ?.every((checked) => checked) ??
                            false
                        ? myBlue30
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: completedSets[exercise['exerciseId'] ??
                                      'exercise_$_currentExerciseIndex']
                                  ?.every((checked) => checked) ??
                              false
                          ? myBlue60
                          : theme.brightness == Brightness.light
                              ? Colors.white
                              : myGrey80,
                      border: Border.all(
                          color: completedSets[exercise['exerciseId'] ??
                                          'exercise_$_currentExerciseIndex']
                                      ?.every((checked) => checked) ??
                                  false
                              ? myBlue60
                              : myGrey60),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light
                                ? Colors.white
                                : completedSets[exercise['exerciseId'] ??
                                                'exercise_$_currentExerciseIndex']
                                            ?.every((checked) => checked) ??
                                        false
                                    ? Colors.white
                                    : myGrey80,
                            border: Border.all(
                                color: completedSets[exercise['exerciseId'] ??
                                                'exercise_$_currentExerciseIndex']
                                            ?.every((checked) => checked) ??
                                        false
                                    ? Colors.white
                                    : myGrey60),
                            shape: BoxShape.circle,
                          ),
                          child: completedSets[exercise['exerciseId'] ??
                                          'exercise_$_currentExerciseIndex']
                                      ?.every((checked) => checked) ??
                                  false
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: myBlue60,
                                )
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          completedSets[exercise['exerciseId'] ??
                                          'exercise_$_currentExerciseIndex']
                                      ?.every((checked) => checked) ??
                                  false
                              ? 'Uncheck All'
                              : 'Check All',
                          style: GoogleFonts.plusJakartaSans(
                            color: completedSets[exercise['exerciseId'] ??
                                            'exercise_$_currentExerciseIndex']
                                        ?.every((checked) => checked) ??
                                    false
                                ? Colors.white
                                : myGrey60,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Add this new section for instructions after the last set
        if (setNumber == (exercise['sets'] as List).length &&
            exercise['instructions'] != null &&
            (exercise['instructions'] as List).isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            //padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              //color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              //border: Border.all(color: myGrey20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 24,
                      color: theme.brightness == Brightness.light
                          ? myGrey80
                          : Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Instructions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: theme.brightness == Brightness.light
                            ? myGrey80
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  (exercise['instructions'] as List).length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
                            ? Colors.white
                            : myGrey80,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.brightness == Brightness.light
                                ? myGrey20
                                : myGrey70),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ',
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.brightness == Brightness.light
                                  ? myGrey80
                                  : Colors.grey[400],
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              exercise['instructions'][index],
                              style: GoogleFonts.plusJakartaSans(
                                color: theme.brightness == Brightness.light
                                    ? myGrey80
                                    : Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSetTextField(
    Map<String, dynamic> exercise,
    String exerciseId,
    int setNumber,
    String field,
    Map<String, List<TextEditingController>> controllers,
    String initialValue,
  ) {
    //final theme = Theme.of(context);
    // Initialize controllers for this exercise if not exists
    if (controllers[exerciseId] == null) {
      final sets = exercise['sets'] as List<dynamic>;
      controllers[exerciseId] = List.generate(
        sets.length,
        (_) => TextEditingController(),
      );
    }

    final controller = controllers[exerciseId]![setNumber];

    // Set initial value only if controller is empty
    if (controller.text.isEmpty) {
      controller.text = initialValue;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        onChanged: (value) {
          actualSetValues[exerciseId]![setNumber][field] = value;
        },
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          //hintText: exercise[field]?.toString() ?? '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: myBlue60),
          ),
        ),
        style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.black),
      ),
    );
  }

  // Update _handleExerciseComplete to use the helper method
  void _handleExerciseComplete(userData, unitPrefs) {
    final currentExercise = exercises[_currentExerciseIndex];
    final exerciseId = _generateExerciseId(
        currentExercise,
        currentExercise['phaseId'],
        exercisesByPhase
            .firstWhere((phase) => phase.id == currentExercise['phaseId'])
            .exercises
            .indexOf(currentExercise));

    // Save current exercise timer
    exerciseTimers[exerciseId] = _exerciseTime;

    if (_currentExerciseIndex < exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
      _startExerciseTimer(); // Reset timer for next exercise
    } else {
      _finishWorkout(userData, unitPrefs);
    }
  }

  void _finishWorkout(userData, UnitPreferences unitPrefs) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? Colors.white
                      : myGrey90,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.workout_difficulty,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Using CustomFitnessLevelSlider for difficulty
                    CustomFitnessLevelSlider(
                      initialLevel: _selectedDifficulty,
                      onLevelChanged: (String level) {
                        _selectedDifficulty = level;
                      },
                      isDifficultySlider: true,
                    ),

                    const SizedBox(height: 24),

                    CustomFocusTextField(
                      controller: _notesController,
                      label: l10n.workout_notes,
                      hintText: l10n.workout_notes_hint,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            Navigator.of(context).pop(); // Close dialog
                            setState(() {
                              _isSubmitting = true;
                            });
                            await _completeWorkout(userData, unitPrefs);
                            setState(() {
                              _isSubmitting = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: myRed30,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 24),
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: myRed50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.submit_and_finish,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isSubmitting)
              const Positioned.fill(
                child: CustomLoadingView(),
              ),
          ],
        );
      },
    );
  }

  // Update _completeWorkout to use the helper method
  Future<void> _completeWorkout(userData, UnitPreferences unitPrefs) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final planId = widget.workout['planId'];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final workoutHistoryId = '${planId}_${widget.selectedDay}_$timestamp';

      final clientId = widget.workout['clientId'];
      final trainerId = widget.workout['trainerId'];
      if (clientId == null) throw 'Client ID not found';

      final weightUnit = userData['weightUnit'];

      // Debug print for completedSets
      debugPrint('CompletedSets state: $completedSets');
      // Debug print for controllers
      debugPrint('Reps Controllers: $repsControllers');
      debugPrint('Weight Controllers: $weightControllers');
      debugPrint('Rest Controllers: $restControllers');

      final workoutData = {
        'workoutHistoryId': workoutHistoryId,
        'planId': planId,
        'clientId': clientId,
        'trainerId': trainerId,
        'isEnteredByTrainer': widget.isEnteredByTrainer,
        'dayNumber': widget.selectedDay,
        'completedAt': FieldValue.serverTimestamp(),
        'totalDuration': _elapsedTime.inSeconds,
        'finishDifficulty': _selectedDifficulty,
        'finishNotes': _notesController.text,
        'phases': exercisesByPhase.map((phase) {
          return {
            'phaseId': phase.id,
            'phaseName': phase.name,
            'exercises': phase.exercises.map((exercise) {
              final index = phase.exercises.indexOf(exercise);
              final exerciseId = _generateExerciseId(exercise, phase.id, index);
              final sets = exercise['sets'] as List<dynamic>;

              debugPrint('Processing exercise: $exerciseId');
              debugPrint(
                  'CompletedSets for this exercise: ${completedSets[exerciseId]}');

              return {
                'exerciseId': exerciseId,
                'name': exercise['name'],
                'equipment': exercise['equipment'],
                'instructions': exercise['instructions'],
                'isBookmarked': savedExercises[exerciseId] ?? false,
                'duration': exerciseTimers[exerciseId]?.inSeconds ?? 0,
                'isCompleted':
                    completedSets[exerciseId]?.every((checked) => checked) ??
                        false,
                'sets': List.generate(sets.length, (setIndex) {
                  final assignedSet = sets[setIndex];
                  final isSetCompleted =
                      completedSets[exerciseId]?[setIndex] ?? false;

                  debugPrint('Set ${setIndex + 1} completed: $isSetCompleted');
                  debugPrint('Exercise ID: $exerciseId, Set Index: $setIndex');

                  String actualReps = '';
                  String actualWeight = '';
                  String actualRest = '';

                  if (isSetCompleted) {
                    debugPrint('Set is completed, checking controllers...');
                    debugPrint(
                        'Reps controller exists: ${repsControllers[exerciseId]?[setIndex] != null}');
                    if (repsControllers[exerciseId]?[setIndex] != null) {
                      actualReps = repsControllers[exerciseId]![setIndex].text;
                      actualWeight = weightUnit == 'kg'
                          ? weightControllers[exerciseId]![setIndex].text
                          : unitPrefs
                              .lbsToKg(double.parse(
                                  weightControllers[exerciseId]![setIndex]
                                      .text))
                              .toStringAsFixed(0);
                      actualRest = restControllers[exerciseId]![setIndex].text;
                      debugPrint(
                          'Actual values - Reps: $actualReps, Weight: $actualWeight, Rest: $actualRest');
                    } else {
                      debugPrint('Controllers not found for completed set');
                    }
                  }

                  final setData = {
                    'setNumber': setIndex + 1,
                    'assigned': {
                      'reps': assignedSet['reps'],
                      'weight': assignedSet['weight'],
                      'rest': assignedSet['rest'],
                    },
                    'actual': {
                      'reps': actualReps,
                      'weight': actualWeight,
                      'rest': actualRest,
                    },
                    'isCompleted': isSetCompleted,
                  };

                  debugPrint('Final set data: $setData');
                  return setData;
                }),
              };
            }).toList(),
          };
        }).toList(),
      };

      // Add feedbacks to workout data
      if (exerciseFeedbacks.isNotEmpty) {
        workoutData['exerciseFeedbacks'] = exerciseFeedbacks;
      }

      debugPrint('Final workout data: $workoutData');

      try {
        //final userId = context.read<UserProvider>().userData?['userId'];
        //if (userId == null) throw 'User ID not found';

        // Create a batch for atomic operations
        final batch = FirebaseFirestore.instance.batch();

        // Set the workout history document
        final historyRef = FirebaseFirestore.instance
            .collection('workout_history')
            .doc('clients')
            .collection(clientId)
            .doc(workoutHistoryId);
        batch.set(historyRef, workoutData);

        // Get all workouts for this client
        final workoutsSnapshot = await FirebaseFirestore.instance
            .collection('workouts')
            .doc('clients')
            .collection(clientId)
            .get();

        // Collect exercise names and their bookmark states from this session
        final exerciseBookmarkStates = <String, bool>{};
        for (var phase in exercisesByPhase) {
          for (var exercise in phase.exercises) {
            final exerciseId = _generateExerciseId(
                exercise, phase.id, phase.exercises.indexOf(exercise));
            // Store the current bookmark state for each exercise
            exerciseBookmarkStates[exercise['name']] =
                savedExercises[exerciseId] ?? false;
          }
        }

        // If we have any exercises to update
        if (exerciseBookmarkStates.isNotEmpty) {
          for (var workoutDoc in workoutsSnapshot.docs) {
            final workoutData = workoutDoc.data();
            final List<dynamic> workoutDays = workoutData['workoutDays'] ?? [];
            bool hasChanges = false;

            // Update bookmarked status for matching exercises
            for (var day in workoutDays) {
              for (var phase in day['phases'] as List<dynamic>) {
                for (var exercise in phase['exercises'] as List<dynamic>) {
                  // If this exercise name exists in our states map
                  if (exerciseBookmarkStates.containsKey(exercise['name'])) {
                    // Update to the new state (whether true or false)
                    final newBookmarkState =
                        exerciseBookmarkStates[exercise['name']]!;
                    if (exercise['isBookmarked'] != newBookmarkState) {
                      exercise['isBookmarked'] = newBookmarkState;
                      hasChanges = true;
                    }
                  }
                }
              }
            }

            // If this workout had any changes, update it
            if (hasChanges) {
              batch.update(workoutDoc.reference, {'workoutDays': workoutDays});
            }
          }
        }

        // Get trainer and client data for feedback
        final userProvider = context.read<UserProvider>();
        final clientData = userProvider.userData;
        final trainerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(trainerId)
            .get();
        final trainerData = trainerDoc.data();

        // Store exercise feedbacks if any exist
        for (var phase in exercisesByPhase) {
          for (var exercise in phase.exercises) {
            final exerciseId = _generateExerciseId(
                exercise, phase.id, phase.exercises.indexOf(exercise));
            final feedback = exerciseFeedbacks[exerciseId];

            if (feedback != null && _hasValidFeedback(exerciseId)) {
              final feedbackId = FirebaseFirestore.instance
                  .collection('exercise_feedbacks')
                  .doc()
                  .id;

              final feedbackRef = FirebaseFirestore.instance
                  .collection('exercise_feedbacks')
                  .doc(trainerId)
                  .collection(clientId)
                  .doc(feedbackId);

              batch.set(feedbackRef, {
                'exerciseId': exerciseId,
                'exerciseName': exercise['name'],
                'exercisePhase': phase.name,
                'workoutPlanId': widget.workout['planId'],
                'workoutPlanName': widget.workout['planName'],
                'workoutDay': widget.selectedDay,
                'selectedAreas': feedback['areas'] ?? [],
                'comment': feedback['comment'] ?? '',
                'trainerId': trainerId,
                'trainerName': trainerData?['fullName'] ?? '',
                'trainerUsername': trainerData?['username'] ?? '',
                'trainerProfileImageUrl': trainerData?['profileImageUrl'] ?? '',
                'clientId': clientId,
                'clientName': clientData?['fullName'] ?? '',
                'clientUsername': clientData?['username'] ?? '',
                'clientProfileImageUrl': clientData?['profileImageUrl'] ?? '',
                'feedbackId': feedbackId,
                'sentAt': FieldValue.serverTimestamp(),
                'isRead': false,
                'readAt': null,
                'workoutHistoryId': workoutHistoryId,
              });
            }
          }
        }

        // After storing feedbacks but before batch.commit()
        final achievementService = AchievementService(
          userProvider: context.read<UserProvider>(),
          userId: clientId,
        );
        await achievementService.checkFeedbackAchievements(exerciseFeedbacks);
        await achievementService.checkStrengthAchievements(
          exercises: exercises,
          completedSets: completedSets,
          weightControllers: weightControllers,
        );

        // Send notification to trainer
        final notificationService = NotificationService();
        if (widget.isEnteredByTrainer == false) {
          await notificationService.createWorkoutCompletedNotification(
            trainerId: trainerId,
            clientId: clientId,
            workoutHistoryId: workoutHistoryId,
            workoutData: {
              'planId': planId,
              'planName': widget.workout['planName'],
              'dayNumber': widget.selectedDay,
              'finishDifficulty': _selectedDifficulty,
              'totalDuration': _elapsedTime.inSeconds,
            },
            clientData: userData,
          );
        }

        // Commit all changes
        await batch.commit();

        // After successfully saving the workout, check for achievements
        await _checkWorkoutAchievements(clientId);

        debugPrint('Workout data saved successfully');


        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.show(
              title: l10n.workout,
              message: l10n.workout_completed_successfully,
              type: SnackBarType.success,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error saving workout: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.show(
              title: l10n.workout,
              message: l10n.failed_to_save_workout_data,
              type: SnackBarType.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error completing workout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.workout,
            message: l10n.failed_to_complete_workout,
            type: SnackBarType.error,
          ),
        );
      }
    }
  }

  Future<void> _checkWorkoutAchievements(String clientId) async {
    try {
      final userProvider = context.read<UserProvider>();
      final achievementService = AchievementService(
        userProvider: userProvider,
        userId: clientId,
      );

      // Check if workout was completed before 8 AM
      final now = DateTime.now();
      final isEarlyBird = now.hour < 8;

      debugPrint('Workout completion time: ${now.hour}:${now.minute}');
      debugPrint('Is early bird workout: $isEarlyBird');

      // Check workout achievements
      await achievementService.checkWorkoutAchievements(
        exercises: exercises,
        completedSets: completedSets,
        workoutDuration: _elapsedTime,
        weightControllers: weightControllers,
        isEarlyBird: isEarlyBird, // Add this parameter
      );

      // Check plan completion if this was the last workout in the plan
      final workoutPlan = widget.workout;
      final currentDay = widget.selectedDay;
      final totalDays = (workoutPlan['workoutDays'] as List).length;

      if (currentDay == totalDays - 1) {
        // If this is the last day
        // Check if all previous days are completed
        final allDaysCompleted =
            await _areAllPreviousDaysCompleted(clientId, workoutPlan['planId']);
        if (allDaysCompleted) {
          await achievementService.checkPlanAchievements(
            planId: workoutPlan['planId'],
            isCompleted: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking workout achievements: $e');
    }
  }

  Future<bool> _areAllPreviousDaysCompleted(
      String clientId, String planId) async {
    try {
      final workoutHistory = await FirebaseFirestore.instance
          .collection('workout_history')
          .doc('clients')
          .collection(clientId)
          .where('planId', isEqualTo: planId)
          .get();

      final completedDays = workoutHistory.docs
          .map((doc) => doc.data()['dayNumber'] as int)
          .toSet();

      // Check if all days before the current day are completed
      for (int i = 0; i < widget.selectedDay; i++) {
        if (!completedDays.contains(i)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error checking previous days completion: $e');
      return false;
    }
  }

  // Update _initializeControllers to accept exerciseId
  void _initializeControllers(
      Map<String, dynamic> exercise, String exerciseId, int setCount) {
    if (repsControllers[exerciseId] == null) {
      repsControllers[exerciseId] = List.generate(
        setCount,
        (_) => TextEditingController(),
      );
      weightControllers[exerciseId] = List.generate(
        setCount,
        (_) => TextEditingController(),
      );
      restControllers[exerciseId] = List.generate(
        setCount,
        (_) => TextEditingController(),
      );
    }
  }

  // Add this method to show the feedback sheet
  void _showFeedbackSheet(String exerciseId, String exerciseName) {
    // Get existing feedback data
    final existingFeedback = exerciseFeedbacks[exerciseId];
    List<String>? selectedAreas;
    String? comment;

    if (existingFeedback != null && existingFeedback is Map<String, dynamic>) {
      selectedAreas = List<String>.from(existingFeedback['areas'] ?? []);
      comment = existingFeedback['comment'] as String?;
    }

    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ExerciseFeedbackSheet(
          exerciseName: exerciseName,
          selectedAreas: selectedAreas, // Pass existing selections
          existingComment: comment, // Pass existing comment
        ),
      ),
    ).then((feedback) {
      if (feedback != null) {
        setState(() {
          exerciseFeedbacks[exerciseId] = {
            'areas': feedback['areas'],
            'comment': feedback['comment'],
          };
        });
      }
    });
  }

  // Add this helper method to the class
  bool _hasValidFeedback(String exerciseId) {
    final feedback = exerciseFeedbacks[exerciseId];
    if (feedback == null) return false;

    return (feedback['areas']?.isNotEmpty == true) ||
        (feedback['comment']?.isNotEmpty == true);
  }

  void _showFullScreenVideo(BuildContext context, String videoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            elevation: 0,
          ),
          body: SafeArea(
            child: Center(
              child: CustomVideoPlayer(
                videoUrl: videoUrl,
                showControls: true,
                showFullscreenButton: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImages(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ImageGalleryScreen(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}
