import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Exercise {
  final String name;
  final String sets;
  final String reps;
  final String? notes;
  final String? weight;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.notes,
    this.weight,
  });
}

class WorkoutDay {
  final String name;
  final String focus;
  final List<Exercise> exercises;
  final int dayNumber;
  final String intensity;
  final String type;

  WorkoutDay({
    required this.name,
    required this.focus,
    required this.exercises,
    required this.dayNumber,
    required this.intensity,
    required this.type,
  });
}

// Rest of the ExerciseCard and its state implementation remains the same...

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showNotes = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildExerciseDetail(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 102, 255).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Color.fromARGB(255, 0, 102, 255),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exercise.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildExerciseDetail('${widget.exercise.sets} sets'),
                        const SizedBox(width: 8),
                        _buildExerciseDetail('${widget.exercise.reps} reps'),
                        if (widget.exercise.weight != null) ...[
                          const SizedBox(width: 8),
                          _buildExerciseDetail(widget.exercise.weight!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.videocam_outlined),
                    color: const Color.fromARGB(255, 0, 102, 255),
                    onPressed: () {
                      // Show exercise video/tutorial
                    },
                  ),
                  if (widget.exercise.notes != null)
                    IconButton(
                      icon: Icon(_showNotes ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                      color: const Color.fromARGB(255, 0, 102, 255),
                      onPressed: () {
                        setState(() {
                          _showNotes = !_showNotes;
                        });
                        if (_showNotes) {
                          _controller.forward();
                        } else {
                          _controller.reverse();
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
          if (widget.exercise.notes != null)
            SizeTransition(
              sizeFactor: _animation,
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.exercise.notes!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class ShortTimeWorkoutPage extends StatefulWidget {
  const ShortTimeWorkoutPage({super.key});

  @override
  State<ShortTimeWorkoutPage> createState() => _ShortTimeWorkoutPageState();
}

class _ShortTimeWorkoutPageState extends State<ShortTimeWorkoutPage> {
  late int _selectedDayNumber;
  final List<WorkoutDay> workoutPlan = [
    WorkoutDay(
      name: "Day 1",
      focus: "Full Body Introduction",
      dayNumber: 1,
      intensity: "Light",
      type: "Strength",
      exercises: [
        Exercise(
          name: "Bodyweight Squats",
          sets: "3",
          reps: "12",
          notes: "Focus on form and warming up properly",
        ),
        Exercise(
          name: "Push-ups",
          sets: "3",
          reps: "10",
          notes: "Modified push-ups on knees if needed",
        ),
        Exercise(
          name: "Dumbbell Rows",
          sets: "3",
          reps: "12",
          weight: "15 lbs",
        ),
      ],
    ),
    WorkoutDay(
      name: "Day 2",
      focus: "Cardio & Core",
      dayNumber: 2,
      intensity: "Moderate",
      type: "Cardio",
      exercises: [
        Exercise(
          name: "Jogging",
          sets: "1",
          reps: "20 mins",
          notes: "Maintain steady pace",
        ),
        Exercise(
          name: "Plank Holds",
          sets: "3",
          reps: "30 secs",
        ),
        Exercise(
          name: "Mountain Climbers",
          sets: "3",
          reps: "20 each leg",
        ),
      ],
    ),
    WorkoutDay(
      name: "Day 3",
      focus: "Rest & Recovery",
      dayNumber: 3,
      intensity: "Low",
      type: "Rest",
      exercises: [
        Exercise(
          name: "Light Walking",
          sets: "1",
          reps: "20 mins",
          notes: "Active recovery - keep it relaxed",
        ),
        Exercise(
          name: "Stretching",
          sets: "1",
          reps: "15 mins",
          notes: "Focus on major muscle groups",
        ),
      ],
    ),
    // ... Continue with days 4-21 following similar pattern but with different exercises
    WorkoutDay(
      name: "Day 21",
      focus: "Final Challenge",
      dayNumber: 21,
      intensity: "High",
      type: "Strength",
      exercises: [
        Exercise(
          name: "Barbell Squats",
          sets: "4",
          reps: "12",
          weight: "135 lbs",
          notes: "Challenge yourself but maintain form",
        ),
        Exercise(
          name: "Bench Press",
          sets: "4",
          reps: "10",
          weight: "115 lbs",
        ),
        Exercise(
          name: "Deadlifts",
          sets: "3",
          reps: "8",
          weight: "165 lbs",
          notes: "Focus on form over weight",
        ),
      ],
    ),
  ];

  String get planDescription {
    final l10n = AppLocalizations.of(context)!;
    return l10n.transformation_challenge;
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'high':
        return Colors.red[400]!;
      case 'moderate':
        return Colors.orange[400]!;
      case 'light':
        return Colors.green[400]!;
      case 'low':
        return Colors.blue[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDayNumber = 1;
  }

  WorkoutDay get selectedWorkout => workoutPlan.firstWhere(
        (day) => day.dayNumber == _selectedDayNumber,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    planDescription,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDaySelector(),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedWorkout.focus,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getIntensityColor(selectedWorkout.intensity).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                selectedWorkout.intensity,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: _getIntensityColor(selectedWorkout.intensity),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                selectedWorkout.type,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // ... Progress button implementation remains the same
                  ],
                ),
                const SizedBox(height: 16),
                ...selectedWorkout.exercises.map((exercise) => ExerciseCard(exercise: exercise)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: workoutPlan.map((workout) {
          bool isSelected = workout.dayNumber == _selectedDayNumber;
          Color intensityColor = _getIntensityColor(workout.intensity);
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDayNumber = workout.dayNumber;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? intensityColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Day',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isSelected ? const Color(0xFF1E293B) : Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workout.dayNumber.toString(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF1E293B) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? intensityColor : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}