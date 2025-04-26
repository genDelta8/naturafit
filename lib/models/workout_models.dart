import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WorkoutPhase {
  final String id;  // Unique identifier
  String name;      // Changeable name
  List<Exercise> exercises;

  WorkoutPhase({
    required this.id,
    required this.name,
    List<Exercise>? exercises,  // Make exercises optional
  }) : exercises = exercises ?? [];  // Initialize as modifiable empty list if null

  // Add dispose method
  void dispose() {
    // Currently no resources to dispose
  }
}

class WorkoutDay {
  final int dayNumber;
  final focusAreaController = TextEditingController();
  List<WorkoutPhase> phases;

  WorkoutDay({
    required this.dayNumber,
    List<WorkoutPhase>? initialPhases,
    BuildContext? context,
  }) : phases = initialPhases ?? [
          WorkoutPhase(
            id: '${DateTime.now().millisecondsSinceEpoch}_0',
            // If context is null, fallback to default string
            name: context != null 
                ? AppLocalizations.of(context)!.main_workout_phase 
                : 'Main Workout Phase',
          ),
        ];

  void dispose() {
    focusAreaController.dispose();
    for (var phase in phases) {
      phase.dispose();
    }
  }
}

class Exercise {
  final String name;
  final String? equipment;
  final List<Map<String, dynamic>> sets;
  final List<String> instructions;
  final File? videoFile;
  final List<File> imageFiles;
  final String? exerciseId;
  Exercise({
    this.exerciseId,
    required this.name,
    this.equipment,
    required this.sets,
    this.instructions = const [],
    this.videoFile,
    this.imageFiles = const [],
  });
} 